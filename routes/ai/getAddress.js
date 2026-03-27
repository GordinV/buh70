'use strict';

require('dotenv').config();
const {GoogleGenerativeAI} = require("@google/generative-ai");

const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');
const Doc = require("../../classes/DocumentTemplate");

async function parseAddress(addressStr) {
    if (!global.fetch) {
        global.fetch = require('node-fetch');
        global.Headers = fetch.Headers;
        global.Request = fetch.Request;
        global.Response = fetch.Response
    }

    const API_KET = global.API_KEY;
    const genAI = new GoogleGenerativeAI(API_KET);
    const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash-lite",
//        model: "gemini-1.5-flash",
        generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.1
        },
    });

    console.log('addressStr', addressStr)

    const prompt = `
    Role: You are a high-precision Address Parser specializing in Estonian geography.
    Task: Analyze the provided input string and extract it into a structured JSON object.
Guidelines:

Locale: All names (street, city, region) must be in Estonian (e.g., "Tallinn", not "Reval"; "Maakond", not "Region"). 
If name of the street or city is not full , then fix this name with coorect one accourding to google maps
The 'region' and 'city' fields are MANDATORY. If it is not provided in the input, you must derive it based on the city or village (e.g., Narva -> Ida-Viru maakond).

Entity Recognition: - If "talu" is mentioned, map it to farmer_name.
If a village is mentioned, distinguish it from the city/town.
Verification: Use your search tools to verify the address exists.
Cross-reference the postal code with the official Estonian postal service (Omniva) logic.
Confirm coordinates (latitude/longitude) if the address is specific enough.
Defaulting: Assume the country is "Eesti" unless explicitly stated otherwise.
JSON Format: Return only a valid JSON object with the following keys:    
{
  "country": "Eesti",
  "region": "maakond",
  "city_or_town": "linn / alev / alevik",
  "district": "linnaosa (if applicable)",
  "village": "küla (if applicable)",
  "street": "tänav / puiestee / tee / prospekt ",
  "house_number": "maja number",
  "apartment_number": "korteri number",
  "farmer_name": "talu nimi (if applicable)",
  "postal_code": "5-digit code",
  "maps_report": "Valid / Not Found / Partial Match",
  "latitude": "float",
  "longitude": "float",
  "full_formatted_address": "Standard Estonian format"
}
    Address string: "${addressStr}"
  `;

    try {
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();
        console.log(text);
        return text;
//    return JSON.parse(text);
    } catch (error) {
        console.error("Error parsing address:", error);
        throw error;
    }
}

//module.exports = {parseAddress};


module.exports = async (req, res) => {

    let addressStr = req.body.address;
    let userId = req.body.userId ? req.body.userId : 2477;
    let rekvId = req.body.rekvId ? req.body.rekvId : 63;
    const documentType = 'REKV';

    // check API key
    if (!global.API_KEY) {
        // load model
        let sql = `select
                       r.properties ->> 'API_KEY' as api_key
                   from
                       ou.rekv r
                   where
                       r.id = ${rekvId}`;
        let data = await db.queryDb(sql, null, null, null, null, null, config);
        global.API_KEY = data.data[0] ? data.data[0].api_key : null;
    }
    let fixedAddress = await parseAddress(addressStr);

    return res.status(200).send(fixedAddress);

}