from fastapi import FastAPI, WebSocket, WebSocketDisconnect, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import uvicorn
import json
import asyncio
import tempfile
import os
from typing import Dict, List
import speech_recognition as sr
from gtts import gTTS
import io
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords

# Download NLTK data
nltk.download('punkt', quiet=True)
nltk.download('stopwords', quiet=True)

app = FastAPI(title="Language Learning API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

manager = ConnectionManager()

class NLPService:
    def __init__(self):
        self.stop_words = set(stopwords.words('english'))
        self.scenarios = {
            'cafe': {
                'greetings': ['hello', 'hi', 'good morning', 'good afternoon'],
                'ordering': ['i would like', 'can i have', 'i want', 'order'],
                'paying': ['bill', 'check', 'pay', 'payment'],
                'farewell': ['thank you', 'thanks', 'goodbye', 'see you']
            }
        }
    
    def analyze_speech(self, text: str, scenario: str = "cafe") -> Dict:
        tokens = word_tokenize(text.lower())
        filtered_tokens = [word for word in tokens if word not in self.stop_words and word.isalnum()]
        
        scenario_data = self.scenarios.get(scenario, {})
        matched_categories = []
        
        for category, phrases in scenario_data.items():
            for phrase in phrases:
                if any(word in phrase for word in filtered_tokens):
                    matched_categories.append(category)
                    break
        
        return {
            "recognized_text": text,
            "matched_categories": matched_categories,
            "vocabulary_score": self._calculate_vocabulary_score(filtered_tokens, scenario),
            "suggestions": self._generate_suggestions(matched_categories, scenario)
        }
    
    def _calculate_vocabulary_score(self, tokens: List[str], scenario: str) -> float:
        scenario_words = set()
        for phrases in self.scenarios.get(scenario, {}).values():
            for phrase in phrases:
                scenario_words.update(phrase.split())
        
        matched_words = len(set(tokens) & scenario_words)
        return matched_words / max(len(scenario_words), 1)
    
    def _generate_suggestions(self, categories: List[str], scenario: str) -> List[str]:
        suggestions = []
        scenario_data = self.scenarios.get(scenario, {})
        
        for category in categories:
            if category in scenario_data:
                suggestions.append(f"Practice {category} phrases")
        
        return suggestions[:3] if suggestions else ["Practice common greetings"]

nlp_service = NLPService()

class SpeechRecognitionService:
    def __init__(self):
        self.recognizer = sr.Recognizer()
    
    async def speech_to_text(self, audio_data: bytes) -> Dict:
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_audio:
                temp_audio.write(audio_data)
                temp_audio.flush()
                
                with sr.AudioFile(temp_audio.name) as source:
                    audio = self.recognizer.record(source)
                
                try:
                    text = self.recognizer.recognize_google(audio)
                    return {"text": text, "confidence": 0.8, "service": "google"}
                except sr.UnknownValueError:
                    return {"text": "", "confidence": 0.0, "error": "Could not understand audio"}
                
        except Exception as e:
            return {"text": "", "confidence": 0.0, "error": str(e)}
        finally:
            if os.path.exists(temp_audio.name):
                os.unlink(temp_audio.name)

class TextToSpeechService:
    async def text_to_speech(self, text: str, language: str = 'en') -> bytes:
        try:
            tts = gTTS(text=text, lang=language, slow=False)
            
            with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as temp_audio:
                tts.save(temp_audio.name)
                with open(temp_audio.name, 'rb') as f:
                    audio_data = f.read()
            
            os.unlink(temp_audio.name)
            return audio_data
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"TTS error: {e}")

speech_service = SpeechRecognitionService()
tts_service = TextToSpeechService()

@app.get("/")
async def root():
    return {"message": "Language Learning API", "status": "running"}

@app.post("/api/speech-to-text")
async def speech_to_text(audio: UploadFile = File(...)):
    audio_data = await audio.read()
    result = await speech_service.speech_to_text(audio_data)
    return result

@app.post("/api/text-to-speech")
async def text_to_speech(text: str, language: str = 'en'):
    audio_data = await tts_service.text_to_speech(text, language)
    return StreamingResponse(
        io.BytesIO(audio_data),
        media_type="audio/mpeg"
    )

@app.post("/api/analyze-speech")
async def analyze_speech(text: str, scenario: str = "cafe"):
    analysis = nlp_service.analyze_speech(text, scenario)
    return analysis

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            if message.get("type") == "user_speech":
                analysis = nlp_service.analyze_speech(message["text"])
                
                await manager.send_personal_message(
                    json.dumps({"type": "speech_analysis", "data": analysis}),
                    websocket
                )
                
    except WebSocketDisconnect:
        manager.disconnect(websocket)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)