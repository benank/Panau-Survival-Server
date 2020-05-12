const fs = require('fs');

const child_process = require('child_process');

const dir = './db_backups';

if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir);
}

const interval = 12; // DB backups once every 12 hours

setInterval(() => {
    CreateBackup();
    console.log(`Created backup at ${GetLogDate()}`);
}, interval * 60 * 1000 * 60);

function CreateBackup()
{
    console.log(execute(`sqlite3 server.db -cmd ".backup ${dir}/${GetLogDate()}.db" ".exit"`));
}

function execute(command)
{
    try {
        return child_process.execSync(command, {stdio: [null, null, null]}).toString();
    } catch (e) {
        return e.toString();
    }
}

console.log("Backups started.")

/**
 * Gets a nicely formatted time string.
 * 
 * @return {string}
 */

function GetTime()
{
    const date = new Date();

    let hour = date.getHours();
    hour = (hour < 10 ? "0" : "") + hour;

    let min  = date.getMinutes();
    min = (min < 10 ? "0" : "") + min;

    let sec  = date.getSeconds();
    sec = (sec < 10 ? "0" : "") + sec;

    return `${hour}-${min}-${sec}`;
}

/**
 * Gets a nicely formatted date string for log filenames.
 * 
 * @return {string}
 */

function GetDate()
{
    const date = new Date();

    let year = date.getFullYear();

    let month = date.getMonth() + 1;
    month = (month < 10 ? "0" : "") + month;

    let day  = date.getDate();
    day = (day < 10 ? "0" : "") + day;

    return `${year}-${month}-${day}`;
}

function GetLogDate()
{
    return `${GetDate()}-${GetTime()}`;
}
