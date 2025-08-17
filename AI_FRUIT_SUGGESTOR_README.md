# AI Fruit Suggestor - Complete Implementation Guide

## 🍎 Overview

The AI Fruit Suggestor is an intelligent chatbot that provides personalized fruit recommendations based on user order history, nutritional needs, and specific questions. It uses the DeepSeek API to generate contextual responses about fruits, nutrition, and dietary advice.

## ✨ Features

### 🤖 AI-Powered Recommendations
- Personalized responses based on order history
- Nutritional analysis of past purchases
- Seasonal fruit recommendations
- Dietary advice and health tips

### 💬 Interactive Chat Interface
- Real-time chat with AI
- Message persistence across sessions
- Typing indicators and loading states
- Error handling and fallback responses

### 📊 Smart Context Analysis
- Analyzes last 5 orders for patterns
- Extracts nutritional information from products
- Considers household size for recommendations
- Tracks user preferences over time

### 🎨 Enhanced UI/UX
- Modern chat interface with message bubbles
- Color-coded messages (user, AI, errors, fallbacks)
- Timestamp display for messages
- Responsive design for all screen sizes
- Pull-to-refresh functionality

## 🏗️ Architecture

### Frontend (Flutter)
```
lib/screens/fruits_suggestor_screen.dart
├── Chat interface with message bubbles
├── Order history analysis
├── Message persistence (SharedPreferences)
├── Error handling and loading states
└── Real-time API communication
```

### Backend (Firebase Cloud Functions)
```
functions/index.js
├── DeepSeek API integration
├── Request validation and error handling
├── Context-aware prompt engineering
├── Response formatting and fallbacks
└── Environment variable management
```

### Data Flow
1. **User Input** → Flutter App
2. **Context Analysis** → Order History + Nutrition Data
3. **API Request** → Firebase Cloud Function
4. **AI Processing** → DeepSeek API
5. **Response** → Formatted Answer
6. **UI Update** → Chat Interface

## 🚀 Quick Setup

### Prerequisites
- Firebase project configured
- DeepSeek API account
- Firebase CLI installed
- Node.js 18+ (for Cloud Functions)

### Step 1: Get DeepSeek API Key
1. Visit [DeepSeek Platform](https://platform.deepseek.com/)
2. Sign up/Login to your account
3. Go to API Keys section
4. Create a new API key
5. Copy the generated key

### Step 2: Configure Environment
```bash
# Navigate to project directory
cd fruit_store_user_app

# Set API key (choose one method)
firebase functions:config:set deepseek.api_key="YOUR_API_KEY"

# Or use the deployment script
./deploy_functions.sh  # Linux/Mac
deploy_functions.bat   # Windows
```

### Step 3: Deploy Functions
```bash
firebase deploy --only functions
```

### Step 4: Test the Feature
1. Open the app
2. Navigate to Fruits Suggestor (drawer menu)
3. Ask questions like:
   - "What fruits should I eat for vitamin C?"
   - "Recommend seasonal fruits for summer"
   - "Which fruits are good for digestion?"

## 🔧 Configuration

### Environment Variables
```bash
# Required
DEEPSEEK_API_KEY=your_api_key_here

# Optional (for email verification)
GMAIL_USER=your_email@gmail.com
GMAIL_APP_PASSWORD=your_app_password
```

### API Parameters
```javascript
// DeepSeek API Configuration
{
  model: 'deepseek-chat',        // AI model
  temperature: 0.7,              // Creativity (0.0-1.0)
  max_tokens: 300,               // Response length
  top_p: 0.8                     // Sampling parameter
}
```

### Prompt Engineering
The system uses context-aware prompts that include:
- User's order history
- Nutritional data from products
- Household size
- Specific user questions
- Seasonal considerations

## 📱 User Interface

### Chat Interface
- **Message Bubbles**: Different colors for user/AI messages
- **Error Handling**: Red-tinted messages for errors
- **Fallback Responses**: Orange-tinted for API issues
- **Timestamps**: Relative time display (e.g., "2m ago")

### Context Panel
- **Order History**: Recent fruit purchases
- **Nutrition Data**: Estimated nutrients from orders
- **Household Size**: Adjustable for personalized recommendations
- **Refresh Button**: Update context data

### Input Area
- **Text Field**: Auto-expanding input
- **Send Button**: Floating action button
- **Loading States**: Disabled during API calls
- **Typing Indicator**: Shows when AI is processing

## 🔍 Troubleshooting

### Common Issues

#### "API key not configured"
```bash
# Solution: Set the environment variable
firebase functions:config:set deepseek.api_key="YOUR_KEY"
firebase deploy --only functions
```

#### "Network error"
- Check internet connection
- Verify Firebase project is active
- Check function logs: `firebase functions:log`

#### "No response from AI"
- Verify DeepSeek API key is valid
- Check API usage limits
- Review function logs for errors

### Debug Commands
```bash
# Check function status
firebase functions:list

# View function logs
firebase functions:log

# Test function locally
firebase emulators:start --only functions

# Check environment variables
firebase functions:config:get
```

## 📊 Performance Optimization

### Caching Strategy
- Message persistence using SharedPreferences
- Context data caching for faster responses
- API response caching (planned)

### Rate Limiting
- DeepSeek free tier: 100 requests/day
- Implemented request throttling
- Error handling for rate limit exceeded

### Response Optimization
- Limited response length (300 tokens)
- Optimized prompts for faster processing
- Fallback responses for API failures

## 🔒 Security Considerations

### API Key Management
- Environment variables for sensitive data
- Never commit keys to version control
- Regular key rotation recommended

### Data Privacy
- User data stays within Firebase ecosystem
- No personal data sent to DeepSeek
- Order history analysis is local

### Input Validation
- Request validation in Cloud Functions
- Sanitized user inputs
- Error handling for malformed requests

## 🎯 Future Enhancements

### Planned Features
- [ ] Product recommendation integration
- [ ] Direct "Add to Cart" from suggestions
- [ ] Nutritional goal tracking
- [ ] Seasonal fruit alerts
- [ ] Recipe suggestions
- [ ] Voice input support

### Advanced AI Features
- [ ] Multi-turn conversations
- [ ] Image recognition for fruits
- [ ] Personalized dietary plans
- [ ] Allergy-aware recommendations
- [ ] Price optimization suggestions

## 📈 Analytics & Monitoring

### Usage Tracking
- Function invocation metrics
- API response times
- Error rates and types
- User engagement patterns

### Cost Monitoring
- DeepSeek API usage tracking
- Firebase function costs
- Storage usage for messages

## 🤝 Contributing

### Development Setup
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Set up Firebase project
4. Configure DeepSeek API key
5. Run locally: `flutter run`

### Code Structure
```
fruits_suggestor_screen.dart
├── State management
├── API communication
├── UI components
├── Data persistence
└── Error handling
```

### Testing
- Unit tests for business logic
- Integration tests for API calls
- UI tests for chat interface
- Performance testing for response times

## 📚 API Documentation

### DeepSeek API Reference
- **Endpoint**: `https://api.deepseek.com/v1/chat/completions`
- **Authentication**: Bearer token
- **Models**: `deepseek-chat`, `deepseek-coder`
- **Rate Limits**: 100 requests/day (free tier)

### Firebase Functions
- **Function**: `deepseekSuggestor`
- **Region**: `asia-south1`
- **Trigger**: HTTP request
- **Timeout**: 60 seconds

## 🆘 Support

### Documentation
- [DeepSeek API Docs](https://platform.deepseek.com/docs)
- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Flutter HTTP Package](https://pub.dev/packages/http)

### Community
- GitHub Issues for bug reports
- Stack Overflow for questions
- Firebase Community for backend issues

---

**Note**: This feature requires an active DeepSeek API key and Firebase project. Make sure to monitor usage and costs regularly. 