import { Pool } from "pg";
import { env } from "../config/env.js";

export const pool = new Pool({
    connectionString: env.DATABASE_URL,
})

export async function testDatabaseConnection() {
    const client = await pool.connect();
    try{
        const result = await client.query("SELECT NOW()");
        console.log("PostgreSQL connected:", result.rows[0]);
    }finally{
        client.release();
    }
}