import { Ajv2020 } from "npm:ajv@8.17.1/dist/2020.js";
import { expect } from "jsr:@std/expect";

const ajv = new Ajv2020({
  allErrors: true,
});
const validate = ajv.compile({
  definitions: {
    A: {
      type: "object",
      properties: {
        a: { type: "number" },
      },
      required: ["a"],
    },
    B: {
      type: "object",
      properties: {
        b: { type: "number" },
      },
      required: ["b"],
    },
    Union: {
      oneOf: [
        {
          $ref: "#/definitions/A",
        },
        {
          $ref: "#/definitions/B",
        },
      ],
    },
  },
  // $ref: "#/definitions/Union",
  oneOf: [{ $ref: "#/definitions/A" }, { $ref: "#/definitions/B" }],
});

const ret = validate({ x: 1, y: 4 });
console.log(ret);

console.log({
  a: validate({ a: 1 }),
  b: validate({ b: 2 }),
  err: validate({ a: 1, b: 2, c: 3 }),
  ab: validate({ a: 1, b: 2 }),
});

Deno.test("prefixItems", () => {
  const schema = {
    type: "array",
    minItems: 2,
    prefixItems: [{ type: "number" }, { type: "string" }],
    // additionalItems: false,
  };
  const validate = ajv.compile(schema);
  expect(validate([1, "a"])).toBe(true);
});

Deno.test("prefixItems with const", () => {
  const schema = {
    type: "array",
    minItems: 2,
    prefixItems: [{ const: "t" }, { type: "string" }],
  };
  const validate = ajv.compile(schema);
  expect(validate(["t", "a"])).toBe(true);
  expect(validate(["none", "a"])).toBe(false);
});
