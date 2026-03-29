const chatBox = document.getElementById('chat-box');
const chatForm = document.getElementById('chat-form');
const userInput = document.getElementById('user-input');
const surpriseButton = document.getElementById('surprise-btn');
const presetButtons = document.querySelectorAll('.preset-btn');

const openers = [
	'Absolutely.',
	'No doubt.',
	'Listen closely.',
	'I computed this with zero confidence.',
	'Breaking news from my imagination:'
];

const subjects = [
	'the moon server',
	'your docker compose aura',
	'that suspicious semicolon',
	'the wifi spirits',
	'a very dramatic nginx config',
	'the keyboard goblin'
];

const actions = [
	'has entered maintenance mode',
	'is emotionally containerized',
	'asked for three snacks and a reboot',
	'is scaling horizontally for no reason',
	'switched to interpretive debugging',
	'is now legally a microservice'
];

const endings = [
	'This is not advice, this is lore.',
	'Please pretend this was deeply meaningful.',
	'I would cite sources, but they escaped.',
	'Confidence: loud. Accuracy: mysterious.',
	'That concludes the professional nonsense.'
];

const surprisePrompts = [
	'predict my week',
	'solve my code with vibes',
	'what is truth',
	'why is docker weird',
	'give me startup idea'
];

function pickRandom(list) {
	return list[Math.floor(Math.random() * list.length)];
}

function appendMessage(text, role) {
	if (!chatBox) {
		return;
	}

	const wrapper = document.createElement('div');
	wrapper.className = role === 'user' ? 'flex justify-end' : 'flex justify-start';

	const bubble = document.createElement('div');
	bubble.className = role === 'user'
		? 'max-w-[80%] rounded-2xl bg-orange-500 px-4 py-3 text-sm text-black'
		: 'max-w-[80%] rounded-2xl border border-neutral-700 bg-neutral-900 px-4 py-3 text-sm text-neutral-100';
	bubble.textContent = text;

	wrapper.appendChild(bubble);
	chatBox.appendChild(wrapper);
	chatBox.scrollTop = chatBox.scrollHeight;
}

function generateYapReply(input) {
	const normalized = input.toLowerCase();

	if (normalized.includes('hello') || normalized.includes('hi')) {
		return 'Hello human. I am chat-not-gpt, CEO of random sentences.';
	}

	if (normalized.includes('help')) {
		return 'I can help by speaking confidently about things I invented 0.2 seconds ago.';
	}

	const sentenceOne = `${pickRandom(openers)} ${pickRandom(subjects)} ${pickRandom(actions)}.`;
	const sentenceTwo = `${pickRandom(openers)} ${pickRandom(subjects)} ${pickRandom(actions)}.`;
	const sentenceThree = pickRandom(endings);

	return `${sentenceOne} ${sentenceTwo} ${sentenceThree}`;
}

function respondToUser(message) {
	appendMessage(message, 'user');

	setTimeout(() => {
		appendMessage(generateYapReply(message), 'bot');
	}, 280);
}

appendMessage('Welcome to chat-not-gpt. Ask anything and receive premium nonsense.', 'bot');

if (chatForm && userInput) {
	chatForm.addEventListener('submit', (event) => {
		event.preventDefault();
		const message = userInput.value.trim();

		if (!message) {
			return;
		}

		respondToUser(message);
		userInput.value = '';
		userInput.focus();
	});
}

if (surpriseButton && userInput) {
	surpriseButton.addEventListener('click', () => {
		const randomPrompt = pickRandom(surprisePrompts);
		userInput.value = randomPrompt;
		userInput.focus();
	});
}

if (presetButtons.length > 0 && userInput) {
	presetButtons.forEach((button) => {
		button.addEventListener('click', () => {
			const prompt = button.getAttribute('data-prompt');
			if (!prompt) {
				return;
			}
			userInput.value = prompt;
			userInput.focus();
		});
	});
}
