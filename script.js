const files = [
    { name: "hig an loe", link: "files/HIGHSANDLOWS.mp3" },
    { name: "i pone", link: "files/IPHONE.mp3" }
];

const container = document.getElementById("file-container");
const list = container.querySelector("ul");

files.forEach(file => {
    const item = document.createElement("li");
    item.innerHTML = `<a href="${file.link}" download>${file.name}</a>`;
    list.appendChild(item);
});
