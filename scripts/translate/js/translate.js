const port = 1780;
const host = "localhost";
const dgram = require("dgram");
const sock = dgram.createSocket("udp4");

sock.on("listening", function () {
    console.log("Server listening...");
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
        const translated_text = await translateText(content.text, content.origin_locale);

        // Escape messages
        Object.keys(translated_text).forEach((key) => {
            translated_text[key] = escape(translated_text[key]);
        });
        
        const send_data = JSON.stringify({type: 'translation', data: {id: content.id, translations: translated_text}});
        const encoded_data = new TextEncoder().encode(send_data);
        sock.send(encoded_data, 0, encoded_data.length, rinfo.port, rinfo.address);
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

const projectId = 'panau-survival';

// Imports the Google Cloud client library
const { Translate } = require('@google-cloud/translate').v2;

// Instantiates a client
const translate = new Translate(
    {
        projectId: 'panau-survival',
        keyFilename: 'panau-survival-dc2db763739b.json'
    }
);

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
async function translateText(text, origin_locale) {
    const [detection] = await translate.detect(text);

    // Get source language
    // const source_locale = detection.language;
    const source_locale = origin_locale;
    const return_text =
    {
        [source_locale]: text
    }

    // Translate to each language
    for (let i = 0; i < Object.keys(active_languages).length; i++) {
        try {
            const target_locale = Object.keys(active_languages)[i];
            if (target_locale != source_locale) {
                const [translation] = await translate.translate(text, target_locale);
                return_text[target_locale] = translation;
            }
        }
        catch (e) {
            console.warn(e);
        }
    }

    // console.log(return_text);

    return return_text;
}