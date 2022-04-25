const hilbertRoutes = []
const ppoints = []
const limit = 10000
const moveAngle = Math.PI/32
const lineSize = 20
const weight = 2
const height = 1080
const width = 1920
const noise = 0.1

const hilbert = x=>x%2==0 ? x/2: 3*x+1;
const move = ({x,y}, angle)=> ({
  x: x+Math.cos(angle+(Math.random()*noise))*lineSize, 
  y: y-Math.sin(angle+(Math.random()*noise))*lineSize
})

for(let i=2; i<limit; i++){
  let n = i
  let route = []
  do {
    route.push(n)
    n = hilbert(n)
  }while(n!=1)
  route.push(1)
  hilbertRoutes.push(route.reverse())
  ppoints.push({x:width*0.95, y:height*0.7, angle:Math.PI/2})
}
console.log(hilbertRoutes)


function setup() {
  createCanvas(width, height);
  background(0);
  frameRate(60);
  strokeWeight(weight);
  stroke(color(161,207, 107, 70))
}

let recording = false
function draw() {
  if(!recording){
    record()
    recording =true
  }

  for(let i=0; i<hilbertRoutes.length; i++){
    if(frameCount - i <=0)
      break;
    let route = hilbertRoutes[i]
    const ix = frameCount - i-1
    if(ix>=route.length)
      continue;

    let side = hilbertRoutes[i][ix] % 2 == 0? 1:-1;
    let newAngle = ppoints[i].angle + moveAngle*side;
    let {x:x1, y:y1} = ppoints[i];
    let {x:x2, y:y2} = move(ppoints[i], newAngle);
    line(x1,y1, x2, y2)

   // console.log(`${i}:${ix}, ppoint:${JSON.stringify(ppoints[i])}, newPoint: ${JSON.stringify(move(ppoints[i], newAngle))}`)

    ppoints[i] = {x:x2,y:y2, angle: newAngle}
    
  }
}




