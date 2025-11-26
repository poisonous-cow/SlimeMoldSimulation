int numAgents = 300_000;
SlimeMoldAgent[] agents;
float[] ax = new float[numAgents];
float[] ay = new float[numAgents];
float[] aa = new float[numAgents];
float[] trail_map;
float[] distancesToCenter;
PGraphics trails;
PShader decayShader;


float senseAngle = radians(5);
int senseDistance = 16;
float turnSpeed = 0.3;
float stepSize = 1.5; // max like 4 ~ 5 or it gets choppy

float decayFactor = 0.9;
float randomWeight = 0.1; // less than 1

void setup() {
    size(600, 600);
    noSmooth();
    frameCount = 60;

    agents = new SlimeMoldAgent[numAgents];

    trail_map = new float[width * height];
    distancesToCenter = new float[width * height];

    for (int i = 0; i < numAgents; i++) {
        ax[i] = random(width);
        ay[i] = random(height);
        aa[i] = random(TWO_PI);
    }

    // trail texture
    trails = createGraphics(width, height);
    trails.beginDraw();
    trails.noStroke();
    trails.background(0);
    trails.endDraw();

    // decay shader
    //decayShader = loadShader("trail_decay.glsl");
    //decayShader.set("decayFactor", 0.95);

    for (int i = 0; i < numAgents; i++) {
        float a = random(TWO_PI); // angle 
        float r = random(width * 0.4); // radius
        // cartesian conversions
        float x = width / 2 + r * cos(a);
        float y = height / 2 + r * sin(a);

        ax[i] = x;
        ay[i] = y;
        aa[i] = a;
    }
}

void draw() {
    trails.beginDraw();
    trails.noStroke();
    trails.noSmooth();
    //trails.fill(0, 10);
    //trails.rect(0, 0, width, height);  // fade effect

    trails.endDraw();

    trails.loadPixels();

    for (int i = 0; i < numAgents; i++) {
        float x = ax[i];
        float y = ay[i];
        float a = aa[i];

        // sample nearby pixels
        int ix = int(x);
        int iy = int(y);

        float fx = ix + int(cos(a) * senseDistance);
        float fy = iy + int(sin(a) * senseDistance);
        float lx = ix + int(cos(a - senseAngle) * senseDistance);
        float ly = iy + int(sin(a - senseAngle) * senseDistance);
        float rx = ix + int(cos(a + senseAngle) * senseDistance);
        float ry = iy + int(sin(a + senseAngle) * senseDistance);

        x = (x + width) % width;
        y = (y + height) % height;
        int idx = iy * width + ix;

        float forward = sampleTrail(fx, fy);
        float left = sampleTrail(lx, ly);
        float right = sampleTrail(rx, ry);

        if (forward > left && forward > right);
        else if (left > right) a -= turnSpeed * random(1 - randomWeight, 1 + randomWeight);
        else if (right > left) a += turnSpeed * random(1 - randomWeight, 1 + randomWeight);
        else a += random(-turnSpeed, turnSpeed) * random(1 - randomWeight, 1 + randomWeight);

        x += cos(a) * stepSize;
        y += sin(a) * stepSize;

        // wrap edges
        if (x < 0) x += width;
        if (x >= width) x -= width;
        if (y < 0) y += height;
        if (y >= height) y -= height;

        ax[i] = x;
        ay[i] = y;
        aa[i] = a;

        // leave trail
        trail_map[idx] = min(trail_map[idx] + 5, 255);
        
        // color map
        distancesToCenter[idx] = distToCenter(x, y);
    }

    trails.beginDraw();

    for (int i = 0; i < trails.pixels.length; i++) {
        int bVal = int(trail_map[i]);
        float distFactor = distancesToCenter[i] / width * 1.4 + 0.5;
        color c = color(bVal / 1.8, bVal / distFactor, bVal, 97);
        trails.pixels[i] = color(c);
        trail_map[i] *= decayFactor;
    }

    trails.updatePixels();

    trails.filter(BLUR, 0.6);

    image(trails, 0, 0);
}

float sampleTrail(float sx, float sy) {
    //if (sx < 0 || sx >= width || sy < 0 || sy >= height) return 0;
    sx = (sx + width) % width;
    sy = (sy + height) % height;
    int ix = int(constrain(sx, 0, width - 1));
    int iy = int(constrain(sy, 0, height - 1));
    return trail_map[iy * width + ix];
}

float distToCenter(float x, float y) {
    return dist(width / 2, height / 2, x, y);
}


