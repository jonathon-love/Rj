
const css = `
#editor-box {
    margin-bottom: 6px ;
    flex-grow: 1 ;
    display: flex ;
    flex-direction: column ;
    position: relative ;
}

#editor {
    border: 1px solid #AAAAAA ;
    flex-grow: 1 ;
}

#toolbar {
    display: flex ;
    position: absolute ;
    top: 4px ;
    right: 24px ;
    z-index: 10 ;
}

#info {
    display: flex ;
    position: absolute ;
    bottom: 4px ;
    right: 16px ;
    color: #333333 ;
}

#run, #config {
    width: 21px ;
    height: 21px ;
    border-radius: 2px ;
    background-size: auto 80% ;
    background-position: center ;
    background-repeat: no-repeat ;
}

#run:hover, #config:hover {
    background-color: #EEEEEE ;
}

#menu {
    opacity: 0 ;
    pointer-events: none ;
    transition: .1s all ;

    display: grid ;
    position: absolute ;
    top: 24px ;
    right: 0px ;
    color: #333333 ;
    background-color: #f4f4f4 ;
    border: 1px solid #C1C1C1 ;
    box-shadow: 0px 0px 5px #C1C1C1 ;
    border-radius: 2px ;
    z-index: 20 ;

    padding: 12px ;
    align-items: center ;
    grid-column-gap: 6px ;
    grid-row-gap: 12px ;
}

#menu.visible {
    opacity: 1 ;
    pointer-events: auto ;
}

#menu > label {
    grid-column: 1 ;
    white-space: nowrap ;
}

#output-label, #output {
    grid-row: 1 ;
}

#output {
    grid-column: 2 / span 2 ;
}

#r-label, #r-version {
    grid-row: 3 ;
}

#figure-size {
    grid-row: 2;
    grid-column: 1 / span 2 ;
    display: grid ;
    justify-content: left ;
    align-items: baseline ;
    grid-gap: 4px ;
    margin: 10px 0px;
}

#figure-size-title {
    grid-column: 1 / span 2;
    margin-bottom: 8px;
    font-weight: bold;
}

#figure-size label {
    padding-left: 12px ;
    grid-column: 1 ;
}

#figure-size input {
    width: 50px;
    grid-column: 2 ;
}

#run {
    background-image: url('data:image/svg+xml;utf-8,<svg id="svg2" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.w3.org/2000/svg" height="24" width="24" version="1.1" xmlns:cc="http://creativecommons.org/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" viewBox="0 0 24 24"><metadata id="metadata10"><rdf:RDF><cc:Work rdf:about=""><dc:format>image/svg+xml</dc:format><dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/><dc:title/></cc:Work></rdf:RDF></metadata><path id="path4" fill="#2a8a2a" d="m3 22v-20l18 10-18 10z"/></svg>');
    /*background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAaCAYAAADFTB7LAAAAa0lEQVR42u3OywnAIBBAwcXSUoCW5D11xDoNCBGNv0MOecJOBSOi1OZMsJ4dvFxEJ1OQnMxBarIKEpNNkJbsBknJYZCSnAYJyVVQziNig7/nZkFEbhTE5HpBVO4dxOXKIDL3BLG5BJ1T6rsbMfep2CaMN00AAAAASUVORK5CYII=');*/
}

#config {
    background-image: url('data:image/svg+xml;utf-8,<svg id="svg2" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.w3.org/2000/svg" height="24" width="24" version="1.1" xmlns:cc="http://creativecommons.org/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" viewBox="0 0 24 24"><metadata id="metadata10"><rdf:RDF><cc:Work rdf:about=""><dc:format>image/svg+xml</dc:format><dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/><dc:title/></cc:Work></rdf:RDF></metadata><path id="path4138" d="m10.949 0.81445c-0.184 0.55195-0.345 1.1-0.592 1.582-0.33 0.647-0.8779 1.2418-1.6793 1.5743a0.8148 0.8148 0 0 1 -0.00195 0 0.8148 0.8148 0 0 1 -0.29688 0.0625c-0.7014 0.2142-1.4003 0.2111-2.0059 0.0156-0.5158-0.1664-1.0185-0.4394-1.541-0.7011l-1.4844 1.4844c0.2607 0.5202 0.5326 1.0213 0.6993 1.537 0.2237 0.6922 0.2568 1.5038-0.0762 2.3067-0.3324 0.8017-0.9272 1.3502-1.5742 1.6812-0.4821 0.247-1.0299 0.408-1.582 0.592v2.1016c0.55131 0.18331 1.098 0.34319 1.5801 0.58984 0.64725 0.33116 1.2435 0.87993 1.5762 1.6816a0.8148 0.8148 0 0 1 0 0.002c0.33482 0.80988 0.2978 1.6245 0.072266 2.3184-0.16768 0.51587-0.43771 1.0108-0.69531 1.5234l1.4844 1.4863c0.51908-0.26021 1.0192-0.53241 1.5352-0.69922 0.6061-0.19594 1.3066-0.20005 2.0098 0.01367a0.8148 0.8148 0 0 1 0.29883 0.0625 0.8148 0.8148 0 0 1 0.00195 0c0.8009 0.33171 1.3487 0.92556 1.6797 1.5723 0.24667 0.48198 0.40777 1.0306 0.5918 1.584h2.1016c0.18394-0.55243 0.34415-1.0996 0.5918-1.582 0.33237-0.64747 0.88431-1.2435 1.6875-1.5781a0.8148 0.8148 0 0 1 0.002 0 0.8148 0.8148 0 0 1 0.29883 -0.0625c0.69736-0.21171 1.3933-0.20721 1.9961-0.01172 0.51399 0.1667 1.0165 0.43945 1.5391 0.70117l1.4844-1.4844c-0.2604-0.51944-0.53262-1.0192-0.69922-1.5352-0.22366-0.69263-0.25638-1.5053 0.07617-2.3086 0.33266-0.80231 0.92859-1.3502 1.5762-1.6816 0.4825-0.24692 1.0302-0.40814 1.582-0.5918v-2.1016c-0.557-0.184-1.109-0.346-1.59-0.593-0.646-0.331-1.236-0.8791-1.567-1.6773a0.8148 0.8148 0 0 1 0 -0.00195 0.8148 0.8148 0 0 1 -0.0625 -0.29688c-0.213-0.7017-0.21-1.4002-0.015-2.0059 0.167-0.5157 0.44-1.019 0.701-1.541l-1.484-1.4843c-0.519 0.2599-1.019 0.5323-1.535 0.6992-0.606 0.1961-1.306 0.2001-2.01-0.0137a0.8148 0.8148 0 0 1 -0.29883 -0.0625 0.8148 0.8148 0 0 1 -0.002 0c-0.8-0.3316-1.348-0.924-1.679-1.5703-0.247-0.4819-0.408-1.0317-0.592-1.586h-2.1016zm1.051 6.371c2.6494 0 4.8145 2.1651 4.8145 4.8145s-2.1651 4.8145-4.8145 4.8145-4.8145-2.165-4.8145-4.814c0-2.6494 2.1651-4.8145 4.8145-4.8145z" transform="matrix(1.0269 0 0 1.0275 -.32291 -.33732)" stroke="#bebed6" fill="#d3d6e3"/></svg>');
    /*background-image: url('data:image/svg+xml;utf-8,<svg id="svg2" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.w3.org/2000/svg" height="24" width="24" version="1.1" xmlns:cc="http://creativecommons.org/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" viewBox="0 0 24 24"><metadata id="metadata10"><rdf:RDF><cc:Work rdf:about=""><dc:format>image/svg+xml</dc:format><dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/><dc:title/></cc:Work></rdf:RDF></metadata><path id="path4" d="m24 13.616v-3.232c-1.651-0.587-2.694-0.752-3.219-2.019v-0.001c-0.527-1.271 0.1-2.134 0.847-3.707l-2.285-2.285c-1.561 0.742-2.433 1.375-3.707 0.847h-0.001c-1.269-0.526-1.435-1.576-2.019-3.219h-3.232c-0.582 1.635-0.749 2.692-2.019 3.219h-0.001c-1.271 0.528-2.132-0.098-3.707-0.847l-2.285 2.285c0.745 1.568 1.375 2.434 0.847 3.707-0.527 1.271-1.584 1.438-3.219 2.02v3.232c1.632 0.58 2.692 0.749 3.219 2.019 0.53 1.282-0.114 2.166-0.847 3.707l2.285 2.286c1.562-0.743 2.434-1.375 3.707-0.847h0.001c1.27 0.526 1.436 1.579 2.019 3.219h3.232c0.582-1.636 0.75-2.69 2.027-3.222h0.001c1.262-0.524 2.12 0.101 3.698 0.851l2.285-2.286c-0.744-1.563-1.375-2.433-0.848-3.706 0.527-1.271 1.588-1.44 3.221-2.021zm-12 2.384c-2.209 0-4-1.791-4-4s1.791-4 4-4 4 1.791 4 4-1.791 4-4 4z" stroke="#bebed6" fill="#d3d6e3"/></svg>');*/
    margin-right: 3px;
}

.ace_editor.ace_autocomplete .ace_completion-highlight {
    color: inherit ;
    text-shadow: none ;
}

.ace_editor.ace_autocomplete .ace_line {
    line-height: 20px ;
}

.ace_icon_data,
.ace_icon_func,
.ace_icon_var,
.ace_icon_ns {
    display: inline-block ;
    width: 24px ;
    background-repeat: no-repeat ;
    background-size: 12px ;
    background-position: center ;
}

.ace_icon_data {
    background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAQklEQVR42mOImrXnPy0wA4jYeu8jVfGowZgG0yTy2jqn/8cFLly4SpYcyMwhajBIETXxEA6K0TAeDePRMMZjMC0wAFMtrQuuiigOAAAAAElFTkSuQmCC');
}

.ace_icon_func {
    background-image: url('data:image/svg+xml;utf-8,<svg id="svg2" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.w3.org/2000/svg" height="24" width="24" version="1.1" xmlns:cc="http://creativecommons.org/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" viewBox="0 0 24 24"><metadata id="metadata10"><rdf:RDF><cc:Work rdf:about=""><dc:format>image/svg+xml</dc:format><dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/><dc:title/></cc:Work></rdf:RDF></metadata><rect id="rect4156" stroke-linejoin="round" transform="matrix(.68881 .72494 -.71658 .69751 0 0)" height="21.611" width="11.215" stroke="#3c6ca5" y="-11.24" x="11.362" stroke-width=".79461" fill="#779fce"/></svg>');
    /*background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAXUlEQVR42mNgIAMETFn+n4HaAGRo7Yk7/6lqOMxQGKaK4eiGUsVwXIZSZDghQ8kynFhDSTKcVEOJMpxcQ/EaPmroEDGUpkmLppmBptmXpgUOTYtImhbqNK2GKK04AWuotkOGMq1EAAAAAElFTkSuQmCC');*/
}

.ace_icon_ns {
    background-image: url('data:image/svg+xml;utf-8,<svg id="svg2" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.w3.org/2000/svg" height="24" width="24" version="1.1" xmlns:cc="http://creativecommons.org/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" viewBox="0 0 24 24"><metadata id="metadata10"><rdf:RDF><cc:Work rdf:about=""><dc:format>image/svg+xml</dc:format><dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/><dc:title/></cc:Work></rdf:RDF></metadata><path id="path4154" d="m11.998 0.60938-10.463 5.707v11.494l10.465 5.585 10.465-5.584v-11.43l-10.467-5.7716zm-0.0039 1.1367a0.5344 0.5344 0 0 1 0.258 0.0664l7.916 4.3652a0.5344 0.5344 0 0 1 -0.0059 0.93945l-7.904 4.2168a0.5344 0.5344 0 0 1 -0.508 -0.002l-7.873-4.2929a0.5344 0.5344 0 0 1 0 -0.9375l7.861-4.2891a0.5344 0.5344 0 0 1 0.25586 -0.066406zm9.0117 6.0488a0.5344 0.5344 0 0 1 0.5293 0.53516v8.6016a0.5344 0.5344 0 0 1 -0.2832 0.4707l-8 4.2676a0.5344 0.5344 0 0 1 -0.78711 -0.4707v-8.5996a0.5344 0.5344 0 0 1 0.2832 -0.4707l8-4.2695a0.5344 0.5344 0 0 1 0.25781 -0.064453z" transform="matrix(1.0573 0 0 1.0527 -.68820 -.62646)" fill="#895ba8"/></svg>');
}

`;

let node = document.createElement('style');
node.innerHTML = css;
document.body.appendChild(node);

module.exports = undefined;
