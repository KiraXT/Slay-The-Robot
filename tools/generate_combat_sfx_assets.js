#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const ROOT_DIR = path.resolve(__dirname, "..");
const OUTPUT_DIR = path.join(ROOT_DIR, "external/audio/sfx");
const sampleRate = 44100;

const SFX_SPECS = {
    card_attack: { duration: 0.12, volume: 0.55, wave: "slash", startHz: 820, endHz: 240, noise: 0.12 },
    card_attack_heavy: { duration: 0.18, volume: 0.70, wave: "thud", startHz: 190, endHz: 82, noise: 0.18 },
    card_skill: { duration: 0.13, volume: 0.42, wave: "chime", startHz: 520, endHz: 780 },
    card_skill_draw: { duration: 0.16, volume: 0.42, wave: "arpeggio", startHz: 420, endHz: 980 },
    card_skill_guard: { duration: 0.14, volume: 0.50, wave: "guard", startHz: 210, endHz: 310, noise: 0.05 },
    card_skill_heal: { duration: 0.18, volume: 0.42, wave: "rise", startHz: 480, endHz: 980 },
    card_skill_item: { duration: 0.12, volume: 0.44, wave: "blip", startHz: 700, endHz: 1180 },
    card_status: { duration: 0.16, volume: 0.42, wave: "wobble", startHz: 300, endHz: 520, noise: 0.05 },
    card_status_heavy: { duration: 0.22, volume: 0.52, wave: "wobble", startHz: 190, endHz: 420, noise: 0.10 },
    card_power: { duration: 0.24, volume: 0.48, wave: "chord", startHz: 220, endHz: 440 },
    card_energy: { duration: 0.12, volume: 0.46, wave: "zap", startHz: 950, endHz: 1800, noise: 0.06 },
    impact_damage: { duration: 0.10, volume: 0.62, wave: "thud", startHz: 130, endHz: 70, noise: 0.20 },
    block_gain: { duration: 0.13, volume: 0.45, wave: "guard", startHz: 280, endHz: 430, noise: 0.04 },
    block_hit: { duration: 0.10, volume: 0.52, wave: "guard", startHz: 180, endHz: 120, noise: 0.12 },
    block_break: { duration: 0.16, volume: 0.62, wave: "crack", startHz: 620, endHz: 90, noise: 0.28 },
    status_apply: { duration: 0.13, volume: 0.42, wave: "wobble", startHz: 260, endHz: 610, noise: 0.06 },
    energy_change: { duration: 0.10, volume: 0.44, wave: "zap", startHz: 760, endHz: 1520, noise: 0.05 },
    pile_draw: { duration: 0.09, volume: 0.36, wave: "paper", startHz: 500, endHz: 850, noise: 0.22 },
    pile_discard: { duration: 0.09, volume: 0.34, wave: "paper", startHz: 430, endHz: 310, noise: 0.24 },
    pile_exhaust: { duration: 0.13, volume: 0.38, wave: "fade", startHz: 620, endHz: 160, noise: 0.18 },
};

function main() {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
    for (const [soundId, spec] of Object.entries(SFX_SPECS)) {
        const samples = synthesize(spec);
        writeWav(path.join(OUTPUT_DIR, `${soundId}.wav`), samples);
    }
    console.log(`Generated ${Object.keys(SFX_SPECS).length} combat placeholder SFX file(s).`);
}

function synthesize(spec) {
    const length = Math.max(1, Math.floor(spec.duration * sampleRate));
    const samples = new Float32Array(length);
    for (let index = 0; index < length; index += 1) {
        const t = index / sampleRate;
        const progress = index / Math.max(1, length - 1);
        const hz = lerp(spec.startHz, spec.endHz, progress);
        const envelope = attackDecayEnvelope(progress);
        const base = waveform(spec.wave, t, hz, progress);
        const noise = deterministicNoise(index, spec.wave) * (spec.noise || 0);
        samples[index] = clamp((base + noise) * envelope * spec.volume, -1, 1);
    }
    return samples;
}

function waveform(wave, t, hz, progress) {
    switch (wave) {
        case "arpeggio":
            return sine(t, hz * (progress < 0.34 ? 1 : progress < 0.67 ? 1.25 : 1.5));
        case "blip":
            return 0.68 * sine(t, hz) + 0.32 * square(t, hz * 2);
        case "chime":
            return 0.70 * sine(t, hz) + 0.20 * sine(t, hz * 2) + 0.10 * sine(t, hz * 3);
        case "chord":
            return 0.45 * sine(t, hz) + 0.35 * sine(t, hz * 1.5) + 0.20 * sine(t, hz * 2);
        case "crack":
            return 0.40 * square(t, hz) + 0.60 * sine(t, hz * (1 + progress * 2));
        case "fade":
            return 0.65 * sine(t, hz) + 0.35 * saw(t, hz);
        case "guard":
            return 0.58 * sine(t, hz) + 0.42 * triangle(t, hz * 0.5);
        case "paper":
            return 0.50 * saw(t, hz) + 0.50 * sine(t, hz * 1.8);
        case "rise":
            return 0.65 * sine(t, hz) + 0.35 * sine(t, hz * 2.01);
        case "slash":
            return 0.65 * saw(t, hz) + 0.35 * sine(t, hz * 1.6);
        case "thud":
            return 0.75 * sine(t, hz) + 0.25 * triangle(t, hz * 0.5);
        case "wobble":
            return sine(t, hz + Math.sin(t * Math.PI * 36) * 24);
        case "zap":
            return 0.60 * square(t, hz) + 0.40 * sine(t, hz * 1.8);
        default:
            return sine(t, hz);
    }
}

function attackDecayEnvelope(progress) {
    const attack = Math.min(1, progress / 0.08);
    const decay = Math.pow(1 - progress, 1.65);
    return attack * decay;
}

function writeWav(filePath, samples) {
    const bytesPerSample = 2;
    const channelCount = 1;
    const dataSize = samples.length * bytesPerSample;
    const buffer = Buffer.alloc(44 + dataSize);
    buffer.write("RIFF", 0);
    buffer.writeUInt32LE(36 + dataSize, 4);
    buffer.write("WAVE", 8);
    buffer.write("fmt ", 12);
    buffer.writeUInt32LE(16, 16);
    buffer.writeUInt16LE(1, 20);
    buffer.writeUInt16LE(channelCount, 22);
    buffer.writeUInt32LE(sampleRate, 24);
    buffer.writeUInt32LE(sampleRate * channelCount * bytesPerSample, 28);
    buffer.writeUInt16LE(channelCount * bytesPerSample, 32);
    buffer.writeUInt16LE(16, 34);
    buffer.write("data", 36);
    buffer.writeUInt32LE(dataSize, 40);
    for (let index = 0; index < samples.length; index += 1) {
        buffer.writeInt16LE(Math.round(clamp(samples[index], -1, 1) * 32767), 44 + index * bytesPerSample);
    }
    fs.writeFileSync(filePath, buffer);
}

function sine(t, hz) {
    return Math.sin(Math.PI * 2 * hz * t);
}

function square(t, hz) {
    return sine(t, hz) >= 0 ? 1 : -1;
}

function saw(t, hz) {
    return 2 * (t * hz - Math.floor(0.5 + t * hz));
}

function triangle(t, hz) {
    return 2 * Math.abs(saw(t, hz)) - 1;
}

function deterministicNoise(index, salt) {
    let value = (index + 1) * 1103515245 + salt.length * 12345;
    value = (value >>> 16) & 0x7fff;
    return value / 0x3fff - 1;
}

function lerp(a, b, progress) {
    return a + (b - a) * progress;
}

function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}

main();
