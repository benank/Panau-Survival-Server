const port = 1777;
const host = "localhost";
const sock = dgram.createSocket("udp4");

sock.on("listening", function () {
    console.log("server listening ");
});

sock.on("error", function (err) {
    console.log("server error:\n" + err.stack);
    sock.close();
});

sock.bind(port, host);

sock.on("message", async function (msg, rinfo) {
    const data = msg.toString();
    console.log("received: " + data);
    console.log(msg);
    console.log(rinfo);
    
    if (data == 'handshake') {return;}
    
    const decoded_data = JSON.parse(data);
    const data_type = decoded_data[1]
    const message = decoded_data[2]
    
    // Chat message
    if (data_type == 'translate_message')
    {
        
    }
    
    // sock.send(translation, 0, translation.length, rinfo.port, rinfo.address);  
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

translateText('Привет');