import {describe, test, expect} from "@jest/globals";
import request from "supertest";
import {createApp} from "../src/app";
import {pruneInvalid} from "../src/services/messaging_service";
import {db} from "../src/firebase";

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

const auth = (t: string) => ({Authorization: `Bearer ${t}`});

describe("pruneInvalid", () => {
  test("prunes only unregistered / invalid tokens, keeping the good ones", () => {
    const out = pruneInvalid(
      [
        {success: true},
        {success: false, error: {code: "messaging/registration-token-not-registered"}},
        {success: false, error: {code: "messaging/internal-error"}}, // transient, keep
      ] as never,
      ["good", "dead", "flaky"],
    );
    expect(out).toEqual(["dead"]);
  });

  test("also prunes invalid-registration-token", () => {
    const out = pruneInvalid(
      [{success: false, error: {code: "messaging/invalid-registration-token"}}] as never,
      ["bad"],
    );
    expect(out).toEqual(["bad"]);
  });
});

describe("device registry", () => {
  test("register then unregister writes/removes users/{uid}/devices/{token}", async () => {
    const a = await mintUser();
    const token = "device-token-abc123";

    const reg = await request(app).post("/me/devices")
      .set(auth(a.idToken)).send({token, platform: "android"});
    expect(reg.status).toBe(200);

    const doc = await db.collection("users").doc(a.uid).collection("devices").doc(token).get();
    expect(doc.exists).toBe(true);

    const unreg = await request(app).delete(`/me/devices/${token}`).set(auth(a.idToken));
    expect(unreg.status).toBe(200);

    const doc2 = await db.collection("users").doc(a.uid).collection("devices").doc(token).get();
    expect(doc2.exists).toBe(false);
  });
});
