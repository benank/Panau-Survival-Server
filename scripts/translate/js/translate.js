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
    }, 3000);
});

sock.bind(port, host);

sock.on("message", async function (msg, rinfo) {
    console.log("Got some data")
    const data = msg.toString();
    console.log(data)
    
    const decoded_data = JSON.parse(data);
    const data_type = decoded_data[0]
    const content = decoded_data[1]
    
    console.log(data_type)
    console.log(content)
    
    // Chat message
    if (data_type == 'message')
    {
        // Translate message and send back
        const translated_text = await translateText(content.text);
        const send_data = JSON.stringify(['translation', {id: content.id, translations: translated_text}]);
        sock.send(send_data, 0, send_data.length, rinfo.port, rinfo.address);
    }
    else if (data_type == 'locale_add')
    {
        // Add language
        if (active_languages.indexOf(content) == -1)
        {
            active_languages.push(content);
        }
    }
    else if (data_type == 'locale_remove')
    {
        // Remove language
        if (active_languages.indexOf(content) == -1 && content != 'en')
        {
            active_languages.splice(active_languages.indexOf(content), 1);
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
const active_languages = ['en'];

// Returns a table of the translated string, like:
/*
{
    ['en']: 'hello there',
    ['ru']: 'Привет'
}

*/
async function translateText(text) {
    const [detection] = await translate.detect(text);

    // Get source language
    const source_locale = detection.language;
    const return_text =
    {
        [source_locale]: text
    }

    // Translate to each language
    for (let i = 0; i < Object.keys(active_languages).length; i++) {
        try {
            const target_locale = active_languages[i];
            if (target_locale != source_locale) {
                const [translation] = await translate.translate(text, target_locale);
                return_text[target_locale] = translation;
            }
        }
        catch (e) {
            console.warn(e);
        }
    }

    console.log(return_text);

    return return_text;
}