/* eslint-disable no-multi-spaces */
var buttonSet = [
    { url: "https://www.gog-games.to/?q=",       title: "GOG Games" },
    { url: "https://steamrip.com/?s=",           title: "SteamRIP" },
    { url: "https://fitgirl-repacks.site/?s=",   title: "FitGirl" },
    { url: "https://dodi-repacks.site/?s=",      title: "DODI" },
    { url: "https://gload.to/?s=",               title: "Gload" },
    { url: "https://scnlog.me/?s=",              title: "SCNLOG" },
    { url: "https://www.tiny-repacks.win/?s=",   title: "Tiny Repacks" },
];
var siteSet = [
    { url: "https://www.gog.com/game/*",           title: "GOG" },
    { url: "https://www.gog.com/en/game/*",        title: "GOG" },
];

/*
All Credit for this userscript goes to Kozinc. I simply removed the unsafe sites from his version. And now I'm adding buttons for other sites based on the r/PiratedGames Megathread.
*/
// ==UserScript==
// @name         GOG Ripper
// @namespace    Tinker
// @author       Tinker
// @version      0.5
// @description  Simply adds a pirate link to all games on the GOG store
// @require      https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js
// @match        https://www.gog.com/game/*
// @match        https://www.gog.com/en/game/*
// @grant        none
// @license      MIT
// @downloadURL 
// @updateURL 
// ==/UserScript==

var siteSetResult = "";

siteSet.forEach((el) => {
    if(!!document.URL.match(el.url)) siteSetResult = el.title;
})

console.log("Games Links: ", siteSetResult);
var appName = "";
switch(siteSetResult) {
    case "GOG":
        appName = document.getElementsByClassName("productcard-basics__title")[0].textContent;
        appName = appName.trim();
        buttonSet.forEach((el) => {
            $("button.cart-button")[0].parentElement.parentElement.append(furnishGOG(el.url+appName, el.title))
        })
        break;
}

function furnishGOG(href, innerHTML) {
    let element = document.createElement("a");
    element.target= "_blank";
    element.style = "margin: 5px 0 5px 0 !important; padding: 5px 10px 5px 10px;";
    element.classList.add("button");
    //element.classList.add("button--small");
    element.classList.add("button--big");
    element.classList.add("cart-button");
    element.classList.add("ng-scope");
    element.href = href;
    element.innerHTML= innerHTML;
    return element;
}
