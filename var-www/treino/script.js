// Dados dos exercícios
const exercises = [
    {
        id: 1,
        name: "Aquecimento - Polichinelo",
        reps: "40\" ",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 2,
        name: "Aquecimento - Corrida estacionária com joelhos altos",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 3,
        name: "1 - Abdômen Canivete",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 4,
        name: "1 - Prancha com toque nos ombros",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 5,
        name: "2 - Agachamento Sumô com Halteres",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 6,
        name: "2 - Avanço Alternado com Halteres (Lunge)",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 7,
        name: "3 - Flexão com Halteres (Renegade Row)",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 8,
        name: "3 - Press Militar com Halteres",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 9,
        name: "4 - Remada Curvada com Barra ou Halteres",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 10,
        name: "4 - Chop Rotacional com Halteres (Woodchopper)",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 11,
        name: "5 - Corrida estacionária com salto (High Knees com salto)",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 12,
        name: "5 - Burpee com Salto",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    {
        id: 13,
        name: "AF - Alongamento Piriforme",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },{
        id: 14,
        name: "AF - Alongamento Flexores do Quadril",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },{
        id: 15,
        name: "AF - Cobra (Extensão de coluna)",
        reps: "40\"",
        gif: "exercises/Abdominal_canivete.gif",
        thumbnail: "exercises/Abdominal_canivete.gif",
        completed: false
    },
    // Adicione mais exercícios aqui
];

let currentExerciseIndex = -1;
let timerInterval = null;
let timerSeconds = 0;
let isTimerRunning = false;

// Inicializar a página
document.addEventListener('DOMContentLoaded', function() {
    loadExerciseList();
});

// Carregar lista de exercícios
function loadExerciseList() {
    const exerciseList = document.getElementById('exerciseList');
    exerciseList.innerHTML = '';
    
    exercises.forEach((exercise, index) => {
        const exerciseItem = document.createElement('div');
        exerciseItem.className = `exercise-item ${exercise.completed ? 'completed' : ''}`;
        exerciseItem.onclick = () => openExercise(index);
        
        exerciseItem.innerHTML = `
            <div class="exercise-thumbnail">
                <img src="${exercise.thumbnail}" alt="${exercise.name}" loading="lazy">
            </div>
            <div class="exercise-details">
                <div class="exercise-name">${exercise.name}</div>
                <div class="exercise-reps">Repetições: ${exercise.reps}</div>
            </div>
            ${exercise.completed ? `
                <div class="check-icon">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <polyline points="20,6 9,17 4,12" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </div>
            ` : ''}
        `;
        
        exerciseList.appendChild(exerciseItem);
    });
}

// Abrir exercício específico
function openExercise(index) {
    currentExerciseIndex = index;
    const exercise = exercises[index];
    
    document.getElementById('exerciseList').style.display = 'none';
    document.getElementById('currentExercise').style.display = 'flex';
    
    document.getElementById('exerciseGif').src = exercise.gif;
    document.getElementById('exerciseTitle').textContent = exercise.name;
    document.getElementById('exerciseReps').textContent = `Repetições: ${exercise.reps}`;
}

// Completar exercício
function completeExercise() {
    if (currentExerciseIndex >= 0) {
        exercises[currentExerciseIndex].completed = true;
        
        // Voltar para a lista
        document.getElementById('currentExercise').style.display = 'none';
        document.getElementById('exerciseList').style.display = 'block';
        
        // Recarregar lista para mostrar o check
        loadExerciseList();
        
        currentExerciseIndex = -1;
    }
}

// Controles do timer
function toggleTimer() {
    if (isTimerRunning) {
        pauseTimer();
    } else {
        startTimer();
    }
}

function startTimer() {
    isTimerRunning = true;
    document.getElementById('playIcon').style.display = 'none';
    document.getElementById('pauseIcon').style.display = 'block';
    
    timerInterval = setInterval(() => {
        timerSeconds++;
        updateTimerDisplay();
    }, 1000);
}

function pauseTimer() {
    isTimerRunning = false;
    document.getElementById('playIcon').style.display = 'block';
    document.getElementById('pauseIcon').style.display = 'none';
    
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
}

function stopTimer() {
    pauseTimer();
    timerSeconds = 0;
    updateTimerDisplay();
}

function updateTimerDisplay() {
    const hours = Math.floor(timerSeconds / 3600);
    const minutes = Math.floor((timerSeconds % 3600) / 60);
    const seconds = timerSeconds % 60;
    
    const display = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    document.getElementById('timerDisplay').textContent = display;
}

// Voltar para lista quando pressionar voltar
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && document.getElementById('currentExercise').style.display === 'flex') {
        document.getElementById('currentExercise').style.display = 'none';
        document.getElementById('exerciseList').style.display = 'block';
        currentExerciseIndex = -1;
    }
});