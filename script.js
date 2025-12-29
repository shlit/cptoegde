
const blogPosts = [
    {
        title: "streaming services are funny",
        date: "December 29, 2025",
        content: `
            <p>so here's the thing that's been driving me absolutely insane lately, everyone's streaming music now, right? spotify, apple music, yoppers. and they're all using these heavily compressed audio formats to save bandwidth and storage.</p>
            
            <p>do people even realize what they're missing? the warmth, the depth, the actual TEXTURE of the music gets completely flattened. it's like looking at a jpeg of a beautiful painting instead of seeing it in person.</p>
            
            <p>artists spend weeks, months, YEARS perfecting every little detail of their sound, and then it gets crushed into a 96kbps stream because spotify lies about their qualities horribly and call "high" 192kbps when it should be 320, very high is ACTUALLY 320, and even then 320 isn't something that should be called very high.</p>
            
            
        `
];


function renderBlogPosts() {
    const blogSection = document.getElementById("blog-posts");
    
    blogPosts.forEach(post => {
        const postElement = document.createElement("article");
        postElement.className = "blog-post";
        
        postElement.innerHTML = `
            <h2>${post.title}</h2>
            <span class="post-date">${post.date}</span>
            <div class="post-content">
                ${post.content}
            </div>
        `;
        
        blogSection.appendChild(postElement);
    });
}


document.addEventListener('DOMContentLoaded', () => {
    renderBlogPosts();
});
