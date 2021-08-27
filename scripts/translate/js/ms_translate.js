require('dotenv').config();

const axios = require('axios').default;
const { v4: uuidv4 } = require('uuid');

const subscriptionKey = process.env.SUBSCRIPTION_KEY;
const endpoint = "https://api.cognitive.microsofttranslator.com";

// Add your location, also known as region. The default is global.
// This is required if using a Cognitive Services resource.
const location = process.env.LOCATION;

const port = 1780;
const host = "localhost";
const dgram = require("dgram");
const sock = dgram.createSocket("udp4");

sock.on("listening", function () {
    console.log("MS translate server listening...");
});

sock.on("error", function (err) {
    console.log("Server error:\n" + err.stack);
    console.log("Server closing...");
    sock.close();
    console.log("Restarting server...");
    setTimeout(() => {
        sock.bind(port, host);
    }, 2000);
});

sock.bind(port, host);

sock.on("message", async function (msg, rinfo) {
    const data = msg.toString();
    
    const decoded_data = JSON.parse(data);
    const data_type = decoded_data[0]
    const content = decoded_data[1]
    
    // Chat message
    if (data_type == 'message')
    {
        // Translate message and send back
        translateText(content.text, content.origin_locale, function(translated_text) {
            // Escape messages
            Object.keys(translated_text).forEach((key) => {
                translated_text[key] = escape(translated_text[key]);
            });
            
            const send_data = JSON.stringify({type: 'translation', data: {id: content.id, translations: translated_text}});
            const encoded_data = new TextEncoder().encode(send_data);
            sock.send(encoded_data, 0, encoded_data.length, rinfo.port, rinfo.address);
        });
    }
    else if (data_type == 'locale_add')
    {
        // Add language
        if (typeof active_languages[content] == 'undefined')
        {
            active_languages[content] = 0;
        }
        
        active_languages[content] += 1;
    }
    else if (data_type == 'locale_remove')
    {
        // Remove language
        if (typeof active_languages[content] != 'undefined' && content != 'en')
        {
            active_languages[content] -= 1;
            if (active_languages[content] <= 0)
            {
                delete active_languages[content];
            }
        }
    }
    else if (data_type == 'locale_reset')
    {
        // Reset languages
        active_languages = 
        {
            ['en']: 1
        }
    }
})

// Languages of people on the server, aka languages to translate to
let active_languages = 
{
    ['en']: 1
}

// Returns a table of the translated string, like:
/*
{
    ['en']: 'hello there',
    ['ru']: 'Привет'
}

*/
function translateText(text, origin_locale, cb) {
    // Get source language
    // const source_locale = detection.language;
    const source_locale = origin_locale;
    const return_text =
    {
        [source_locale]: text
    }
    
    // Get list of languages to translate to, not including source zlocale
    const languages_to_translate_to = Object.keys(active_languages).filter((lang) => 
    {
        return lang != source_locale;
    })
    
    // No translation needed
    if (languages_to_translate_to.length == 0)
    {
        return cb(return_text);
    }
    
    // Translate to all other languages
    axios({
        baseURL: endpoint,
        url: '/translate',
        method: 'post',
        headers: {
            'Ocp-Apim-Subscription-Key': subscriptionKey,
            'Ocp-Apim-Subscription-Region': location,
            'Content-type': 'application/json',
            'X-ClientTraceId': uuidv4().toString()
        },
        params: {
            'api-version': '3.0',
            'from': source_locale,
            'to': languages_to_translate_to
        },
        data: [{
            'text': text
        }],
        responseType: 'json'
    }).then(function(response){
        
        response.data[0].translations.forEach((translation) => {
            return_text[translation.to] = translation.text;
        });
        
        cb(return_text);
    }).catch(function(error) {
        console.log(error);  
    })
}