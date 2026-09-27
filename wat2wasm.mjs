import { readFileSync, writeFileSync } from "node:fs";
import wabtInit from "wabt";
const wabt = await wabtInit();
const m = wabt.parseWat(process.argv[2], readFileSync(process.argv[2], "utf8"), { mutable_globals: true, bulk_memory: true });
m.validate();
writeFileSync(process.argv[3], Buffer.from(m.toBinary({}).buffer));
