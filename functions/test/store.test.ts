import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";

jest.setTimeout(90000);
const app = createApp();

async function mintUser(): Promise<{idToken: string; uid: string}> {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const res = await fetch(
    `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({returnSecureToken: true})},
  );
  const data = (await res.json()) as {idToken: string; localId: string};
  return {idToken: data.idToken, uid: data.localId};
}

// Give the user a starting wallet (purchases require coins earned by playing).
async function setCoins(uid: string, coins: number): Promise<void> {
  await admin.firestore().collection("users").doc(uid).set({coins}, {merge: true});
}

describe("store", () => {
  test("GET /store lists the catalog; 401 without auth", async () => {
    expect((await request(app).get("/store")).status).toBe(401);
    const {idToken} = await mintUser();
    const res = await request(app).get("/store").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
    expect(res.body.items.some((i: {id: string}) => i.id === "hint")).toBe(true);
    expect(res.body.items.some((i: {id: string}) => i.id === "freeze_letter")).toBe(true);
  });

  test("purchase debits coins and grants inventory, reflected on /me", async () => {
    const {idToken, uid} = await mintUser();
    await setCoins(uid, 500);
    const res = await request(app).post("/store/purchase")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "p1")
      .send({itemId: "hint", quantity: 3});
    expect(res.status).toBe(200);
    expect(res.body.coins).toBe(350); // 500 - 3*50
    expect(res.body.inventory.hint).toBe(3);

    const me = await request(app).get("/me").set("Authorization", `Bearer ${idToken}`);
    expect(me.body.coins).toBe(350);
    expect(me.body.inventory.hint).toBe(3);
  });

  test("a bundle grants its base items", async () => {
    const {idToken, uid} = await mintUser();
    await setCoins(uid, 1000);
    const res = await request(app).post("/store/purchase")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "b1")
      .send({itemId: "skirmish_pack"});
    expect(res.status).toBe(200);
    expect(res.body.coins).toBe(500); // 1000 - 500
    expect(res.body.inventory).toMatchObject({freeze_letter: 2, fog: 2, shield: 1});
  });

  test("insufficient coins -> 402 and no state change", async () => {
    const {idToken, uid} = await mintUser();
    await setCoins(uid, 10);
    const res = await request(app).post("/store/purchase")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "x1")
      .send({itemId: "word_steal"});
    expect(res.status).toBe(402);
    const me = await request(app).get("/me").set("Authorization", `Bearer ${idToken}`);
    expect(me.body.coins).toBe(10);
    expect(me.body.inventory.word_steal).toBeUndefined();
  });

  test("an unknown item is rejected (400)", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).post("/store/purchase")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "u1")
      .send({itemId: "definitely_not_real"});
    expect(res.status).toBe(400);
  });

  test("replaying the same idempotency-key charges exactly once", async () => {
    const {idToken, uid} = await mintUser();
    await setCoins(uid, 500);
    const post = () => request(app).post("/store/purchase")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "same")
      .send({itemId: "hint", quantity: 2});
    const first = await post();
    const second = await post();
    expect(first.body.coins).toBe(400);
    expect(second.body.coins).toBe(400); // unchanged
    expect(second.body.replay).toBe(true);
    const me = await request(app).get("/me").set("Authorization", `Bearer ${idToken}`);
    expect(me.body.coins).toBe(400);
    expect(me.body.inventory.hint).toBe(2);
  });

  test("quantity is clamped to the item's maxPerPurchase", async () => {
    const {idToken, uid} = await mintUser();
    await setCoins(uid, 100000);
    // word_steal maxPerPurchase is 5; asking for 99 should charge for 5.
    const res = await request(app).post("/store/purchase")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "clamp1")
      .send({itemId: "word_steal", quantity: 99});
    expect(res.status).toBe(200);
    expect(res.body.inventory.word_steal).toBe(5);
    expect(res.body.charged).toBe(260 * 5);
  });

  test("401 without auth on purchase", async () => {
    const res = await request(app).post("/store/purchase")
      .set("idempotency-key", "n1").send({itemId: "hint"});
    expect(res.status).toBe(401);
  });
});
