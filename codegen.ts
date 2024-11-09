import { CodegenConfig } from "@graphql-codegen/cli";
import path from "path";
import dotenv from "dotenv";
dotenv.config({
  path: path.resolve(
    process.cwd(),
    process.env.NODE_ENV === "development"
      ? ".env.development"
      : ".env"
  ),
});

const config: CodegenConfig = {
  schema: process.env.VITE_API_ENDPOINT ?? "https://www.pkuru.com/graphql",
  // documents: ['src/**/*.tsx'],
  generates: {
    "./data/schema.graphql": {
      plugins: ["schema-ast"],
    },
  },
};

export default config;
