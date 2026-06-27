const float enemyWidth=  16.0f;
const float enemyHeight=  16.0f;
const float mouseWidth=  16.0f;
const float mouseHeight=  16.0f;
typedef struct Enemys {
  float x,y;
  
}Enemy;

typedef struct Mouse {
  float x,y;
}Mouse;

Enemy enemies[16];
Mouse mouses[16];

int hitdetection() {
  for(int i = 0; i < 16; i++) {
    for(int k = 0; k < 16; k++) {
      Enemy* currentEnemy = &enemies[i];
      Mouse* currentMouse = &mouses[i];
      if( 
        currentMouse->x < currentEnemy->x+enemyWidth && 
        currentMouse->x+mouseWidth > currentEnemy->x &&
        currentMouse->y < currentEnemy->y+enemyHeight && 
        currentMouse->y+mouseHeight > currentEnemy->y 
      ) {
        return 1;
      }
    }
  }
  return 0;
}

// function EnemyHit(pass in type of bullet) -> we apply damage inside enemy hit 
// if enemyhealth < 0 ->  push onto the remove Enemy stack
// push bulletINdex onto the remove stack 

