const chatBox = document.getElementById('chat-box');
const chatForm = document.getElementById('chat-form');
const userInput = document.getElementById('user-input');

const staticReplies = [
	{
		keywords: ['hello', 'hi', 'hey'],
		reply: 'Hello! I am your static AI chatbot for testing.'
	},
	{
		keywords: ['who are you', 'what are you'],
		reply: 'I am a frontend-only chatbot with predefined answers.'
	},
	{
		keywords: ['help', 'commands'],
		reply: 'You can ask about docker, volumes, nginx, wordpress, or say bye.'
	},
	{
		keywords: ['docker'],
		reply: 'Docker packages apps into containers so they run consistently.'
	},
	{
		keywords: ['volumes', 'volume'],
		reply: 'Volumes store persistent data outside container lifecycles.'
	},
	{
		keywords: ['nginx'],
		reply: 'NGINX is acting as your reverse proxy and HTTPS entrypoint.'
	},
	{
		keywords: ['wordpress'],
		reply: 'WordPress is served by php-fpm behind NGINX in your stack.'
	},
	{
		keywords: ['bye', 'goodbye'],
		reply: 'Goodbye! Refresh the page to start a new chat session.'
	}
];

function appendMessage(text, role) {
	if (!chatBox) {
		return;
	}
	const message = document.createElement('div');
	message.className = `message ${role}`;
	message.textContent = text;
	chatBox.appendChild(message);
	chatBox.scrollTop = chatBox.scrollHeight;
}

function getStaticReply(input) {
	const normalized = input.toLowerCase().trim();

	for (const item of staticReplies) {
		if (item.keywords.some((keyword) => normalized.includes(keyword))) {
			return item.reply;
		}
	}

	return 'I only support predefined answers right now. Try: hello, help, docker, volumes, nginx, wordpress, bye.';
}

appendMessage('Hi! Ask me something and I will answer from a static set.', 'bot');

if (chatForm && userInput) {
	chatForm.addEventListener('submit', (event) => {
		event.preventDefault();
		const message = userInput.value.trim();

		if (!message) {
			return;
		}

		appendMessage(message, 'user');
		appendMessage(getStaticReply(message), 'bot');
		userInput.value = '';
		userInput.focus();
	});
}
