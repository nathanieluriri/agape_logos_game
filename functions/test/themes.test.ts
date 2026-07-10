import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";

const app = createApp();
async function mintUser(): Promise<string> {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const res = await fetch(
    `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({returnSecureToken: true})},
  );
  return ((await res.json()) as {idToken: string}).idToken;
}

describe("themes", () => {
  test("empty when unseeded; 401 without auth", async () => {
    expect((await request(app).get("/themes")).status).toBe(401);
    const token = await mintUser();
    const res = await request(app).get("/themes").set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.themes).toEqual([]);
  });

  test("lists + filters by q once seeded", async () => {
    await admin.firestore().collection("themes").doc("nature").set({id: "nature", name: "Nature"});
    await admin.firestore().collection("themes").doc("food").set({id: "food", name: "Food"});
    const token = await mintUser();
    const all = await request(app).get("/themes").set("Authorization", `Bearer ${token}`);
    expect(all.body.themes.length).toBeGreaterThanOrEqual(2);
    const filtered = await request(app).get("/themes?q=nat").set("Authorization", `Bearer ${token}`);
    expect(filtered.body.themes.map((t: {id: string}) => t.id)).toContain("nature");
    expect(filtered.body.themes.map((t: {id: string}) => t.id)).not.toContain("food");
  });
});
