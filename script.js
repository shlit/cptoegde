// Blog posts data
const blogPosts = [
    {
        title: "why audio compression is ruining music",
        date: "December 28, 2024",
        content: `
            <p>okay so here's the thing that's been driving me absolutely insane lately. everyone's streaming music now, right? spotify, apple music, whatever. and they're all using these heavily compressed audio formats to save bandwidth and storage.</p>
            
            <p>but like, do people even realize what they're missing? the warmth, the depth, the actual TEXTURE of the music gets completely flattened. it's like looking at a jpeg of a beautiful painting instead of seeing it in person.</p>
            
            <p>i'm not even talking about being an audiophile snob here. i'm talking about the fact that artists spend weeks, months, YEARS perfecting every little detail of their sound, and then it gets crushed into a 256kbps stream that sounds like it's being played through a tin can.</p>
            
            <p>anyway, that's my rant for today. if you actually care about music, at least try listening to lossless formats sometime. your ears will thank you.</p>
        `
    },
    {
        title: "the cult of vintage audio gear",
        date: "December 20, 2024",
        content: `
            <p>let me tell you about the vintage audio gear cult. these people will spend thousands of dollars on some dusty old amplifier from the 70s and swear it sounds better than anything modern.</p>
            
            <p>and look, i get it. there's something cool about analog warmth and tube saturation. i'm not saying it's all placebo. but when you're paying $3000 for a 50-year-old preamp that might die tomorrow instead of getting something new with a warranty... come on.</p>
            
            <p>the worst part? the gatekeeping. if you're not using all-analog, vacuum tube everything, you're apparently not a "real" audio enthusiast. meanwhile i'm over here with my digital setup getting 99.9% of the way there for a fraction of the cost.</p>
            
            <p>respect the old gear, sure. but can we stop pretending new = bad?</p>
        `
    },
    {
        title: "my audio files",
        date: "December 15, 2024",
        content: `
            <p>so i've been making some stuff. nothing fancy, just experimenting with sounds and seeing what happens.</p>
            
            <p>"hig an loe" is basically me messing around with dynamics and compression. trying to capture that feeling of highs and lows (obviously). it's raw, unpolished, and that's kind of the point.</p>
            
            <p>"i pone" is just... look, i don't know what it is either. i recorded it on my phone one day and it turned into this weird ambient thing. sometimes accidents are the best creative decisions.</p>
            
            <p>you can download them below if you want. no pressure. they're just there.</p>
        `
    }
];

// Render blog posts
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

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    renderBlogPosts();
});
