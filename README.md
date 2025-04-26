# River Rush Adventure


## Game Overview
River Rush Adventure is a digital board game, reimagined with new characters and enhanced visuals. Players race across a river, dodging obstacles and using special abilities to reach the finish line first.

## Game Mechanics
- **Dice Rolling**: Players roll dice to determine movement
  - Regular faces (1-3) with 60% probability
  - Brown faces (1-3) with 40% probability (triggers log movement)
- **Obstacle Avoidance**: Dodge rolling logs that can knock players back to checkpoints
- **Special Actions**: 
  - Duck: Safe spots that protect from logs
  - Frog: Jump forward to a specific rock
  - Switch: Return to your previous position
  - Dice: Roll again for an extra turn
- **Checkpoints**: Safe spots that allow players to restart from that point if knocked off
- **Multiple Players**: Support for 2-4 players with unique colored paths
- **AI Players**: Optional computer-controlled opponent

## Latest Updates

### Game Logic Improvements
- **Move Validation**: Players can only move if the dice roll allows a valid move (prevents overshooting the end)
- **AI Improvements**: Enhanced AI player with thinking animation and proper turn management
- **End Game Logic**: Game ends when majority of players reach the finish line
- **Pause Menu**: Added ability to pause the game

### Visual Enhancements
- **Player Animations**: Bounce animation for the current player
- **Dice Visuals**: Dynamic dice rolling animation with weighted probabilities
- **Game Over Screen**: Shows final rankings when game ends

## Development Plan

### Phase 1: Core Mechanics ✓
- Set up basic game board ✓
- Implement player movement and turns ✓
- Create dice rolling system ✓
- Add basic obstacle mechanics ✓

### Phase 2: Game Logic ✓
- Implement special actions ✓
- Add checkpoint system ✓
- Create win condition ✓
- Implement multiplayer turns ✓

### Phase 3: Visual Polish ⚙️
- Enhance 3D visuals ✓
- Add animations ✓
- Create particle effects ⚙️
- Polish UI elements ✓

### Phase 4: Sound & Final Polish ⚙️
- Add sound effects ⚙️
- Add background music ⚙️
- Final testing and balancing ⚙️

## Technical Details
- Built with Godot Engine 4.4
- Cross-platform support (PC and Mobile)
- 3D visuals with stylized art direction
- Responsive design that adapts to different screen sizes