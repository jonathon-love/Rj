
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
    right: 20px ;
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
    width: 24px ;
    height: 20px ;
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
    background-color: #F0F0F0 ;
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
    background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAaCAYAAADFTB7LAAAAa0lEQVR42u3OywnAIBBAwcXSUoCW5D11xDoNCBGNv0MOecJOBSOi1OZMsJ4dvFxEJ1OQnMxBarIKEpNNkJbsBknJYZCSnAYJyVVQziNig7/nZkFEbhTE5HpBVO4dxOXKIDL3BLG5BJ1T6rsbMfep2CaMN00AAAAASUVORK5CYII=');
}

#config {
    background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAYAAACpSkzOAAAD3UlEQVR42mNgIBKoqJjzqWgbailr6zuqa+s5aejrqzGEhjIzUBuALLl58/b2r9++ffn2/fuPo8eOzVTUNJSnyFBFHR1xFRUVdrgA0OWu3n5+QAt+/vj58z8Iv37z5paqlp45sj4pY2MuIMVI0AI9PT1uDX1jt7UbNzanZOVGKmkaqII0Kuvpia1Zt6ERZgkIf//x44+Dm5cPyBEgfWq6xhqVNXWJ+maW7pqaxpJ4LVLVMdK8euPGepBBwCD6uv/w4Sk6xuZualr6NvcfPjyEbBEIz5w7txgUV16BIf6Xr11bD7T874vXr69kFRRHgxyH1RIlY2P+iZOn5aIb9ubduwcfPn58ji4Owl++fv1w6crVVR8/f36DLP7k2bOzKnp6Rrg8xGhibe2Jy1BS8PMXLy6p6xia4Aw6DQMDhd179/VRYgkw+H43tXemKWiZSuCLJpivXpBr0YVLl1eq6+mp47RBQcGBQ0nLWM7I0sbj/YcPT7AZ8u79h0e3bt/dBYyDUyCXY1MzZ96CEhVDQ1EZS0tOLS0tNnhyl9PVFVTXMdLLKSqJOXj46FRQ+GIx4B9IDpT0VbT0tUERDQqej58+vUJX+/jJk1ONbW2pRaVVcTFJqWEgh4NKFQaQJfcePDiALzhAJQKoZEDOjMDgUZy/cHE5oaC8efv2NrBeNT1DZ1CRgk/x/MVLyzU0zIQxEg/Qh0C93/DpBebHb6DykQFUQBJSPHXmzEIFAwMBjPJP19D+85cv7/HpffbixXllXSNjBlAxs3Lt2vq79x/sAxWY2BSfOnN2vrK2kQqyJerqhlIdvb2ZuCwAOQBUmkyfM68QVHZCXAZMJRq6urom1k6ee/bun4DF+59BEQxKtqByDBQ/oEL25evXN9DV3r//YG99a3sKKFhB8a+trS2ELZUzgRRg8xkoHq9cu7Zu89bt7SdOnp77/uPHZ9h8EpeSHo4tmFHLO2A+mrdoURklJUNpVW0CtoQDBw4ODizWdo5ewMz6mBKLHj5+fFRN21Afbzl39OTJ2ZQWqODssGRZBU5fgYLt0OGj09Dj5czZ80uu37ixCcj+hW4gKJ5u3rq1FV0OJAbN4FgBE6iSAxWKwOz7DxQEoAoMVLGBihxQHYNsGLAqvw0uXoAGglIksN66DbYcGPSgokddXZ0XZ/CBCkJQlZyeWxAJCmeY91V1dZVOnzm3ENkiYIW3GtwSAgI1fX1pUNYAlSCg0h8UOkQ1TkAlOTIflBfQy7WVa9c3oFXXTFCHMZLfLIK2gkAlOyg+gBn1akhUbJCxsTEr1dt1oBoTVD2DCmFgY8WMYEsHDQAAEK8m0dYP6qQAAAAASUVORK5CYII=');
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
    background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAXUlEQVR42mNgIAMETFn+n4HaAGRo7Yk7/6lqOMxQGKaK4eiGUsVwXIZSZDghQ8kynFhDSTKcVEOJMpxcQ/EaPmroEDGUpkmLppmBptmXpgUOTYtImhbqNK2GKK04AWuotkOGMq1EAAAAAElFTkSuQmCC');
}

.ace_icon_ns {
    background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAA/UlEQVR42mOoVLgwEYjfAvF/KuB3IPPqta6wMVDJQBRcpXChgyYGg0KAoMEfXv38f+PEh//bpjwBs0Hgx9c/YD4+fXgNbrG5DDfoxf1v/0+sfwXGID4IzEy5RZ7BII0gADIUWXz/oudg8Qt73pJn8NrWB2ADQAZhs/DBlc/kGQxzGXp49gdeB4uDwp4sg0FeBYHFZXdRxEF8ioIC5FUQAEUisjgoArH5hGiDQckLlAKQDQYFA0gMJEd2cgMZgCupkZ2OYTEPCkeY12FJD5RaCGUsBlKTGrGYgdSkRrHBMO+jJzWKDYYlNVAqoKrBNC82ycSdDNCq6R3Vq6YhBwC4+XcNbpksvQAAAABJRU5ErkJggg==');
}

`;

let node = document.createElement('style');
node.innerHTML = css;
document.body.appendChild(node);

module.exports = undefined;
