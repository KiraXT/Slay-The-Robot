#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const ROOT_DIR = path.resolve(__dirname, "..");
const CARD_DIR = path.join(ROOT_DIR, "external/data/cards");
const PRESENTATION_FIELDS = [
    "card_visual_profile",
    "card_play_sfx",
    "card_impact_vfx",
    "card_screen_shake",
    "card_hit_pause",
];

const CARD_TYPES = {
    ATTACK: 0,
    SKILL: 1,
    POWER: 2,
    CURSE: 3,
};

const ACTION_ARRAY_FIELDS = [
    "card_play_actions",
    "card_draw_actions",
    "card_discard_actions",
    "card_exhaust_actions",
];

const MANUAL_PRESENTATION_OVERRIDES = {
    card_bomb: {
        card_play_sfx: "card_status_heavy",
        card_impact_vfx: "status_burst",
        card_screen_shake: "medium",
        card_hit_pause: 0.04,
    },
    card_duplicate_attacks: {
        card_play_sfx: "card_power",
        card_impact_vfx: "power_aura",
        card_screen_shake: "",
        card_hit_pause: 0.025,
    },
    card_energy_on_draw: {
        card_play_sfx: "card_energy",
        card_impact_vfx: "energy_surge",
    },
    card_energy_on_discard: {
        card_play_sfx: "card_energy",
        card_impact_vfx: "energy_surge",
    },
    card_something_fell_out: {
        card_play_sfx: "card_skill",
        card_impact_vfx: "skill_spark",
    },
};

function main() {
    const args = process.argv.slice(2);
    const unknownArgs = args.filter((arg) => !["--check", "--write"].includes(arg));
    if (unknownArgs.length > 0) {
        printUsage();
        console.error(`Unknown argument: ${unknownArgs.join(", ")}`);
        process.exit(2);
    }

    const writeChanges = args.includes("--write");
    const failures = [];
    let updatedCount = 0;

    for (const cardPath of getCardPaths()) {
        const originalSource = fs.readFileSync(cardPath, "utf8");
        const cardJson = JSON.parse(originalSource);
        const properties = cardJson.properties || {};
        const expectedPresentation = inferPresentation(properties);
        const cardObjectId = String(properties.object_id || path.basename(cardPath, ".json"));
        let changed = false;

        for (const fieldName of PRESENTATION_FIELDS) {
            const actualValue = properties[fieldName];
            const expectedValue = expectedPresentation[fieldName];
            if (actualValue === expectedValue) {
                continue;
            }
            if (writeChanges) {
                properties[fieldName] = expectedValue;
                changed = true;
            } else {
                failures.push(`${cardObjectId} ${fieldName}: expected ${JSON.stringify(expectedValue)}, got ${JSON.stringify(actualValue)}`);
            }
        }

        if (writeChanges && changed) {
            fs.writeFileSync(cardPath, `${JSON.stringify(cardJson, null, 4)}\n`, "utf8");
            updatedCount += 1;
        }
    }

    if (failures.length > 0) {
        for (const failure of failures) {
            console.error(failure);
        }
        console.error("Card presentation config is out of date. Run with --write to update JSON files.");
        process.exit(1);
    }

    if (writeChanges) {
        console.log(`Updated ${updatedCount} card presentation config file(s).`);
    } else {
        console.log("Card presentation config is up to date.");
    }
}

function printUsage() {
    console.error("Usage: node tools/generate_card_presentation_config.js [--check|--write]");
    console.error("  --check  Validate card presentation fields without writing. This is the default.");
    console.error("  --write  Rewrite mismatched presentation fields in external/data/cards/*.json.");
}

function getCardPaths() {
    return fs.readdirSync(CARD_DIR)
        .filter((fileName) => fileName.endsWith(".json"))
        .sort()
        .map((fileName) => path.join(CARD_DIR, fileName));
}

function inferPresentation(properties) {
    const objectId = String(properties.object_id || "");
    return {
        ...inferBasePresentation(properties),
        ...(MANUAL_PRESENTATION_OVERRIDES[objectId] || {}),
    };
}

function inferBasePresentation(properties) {
    switch (properties.card_type) {
        case CARD_TYPES.ATTACK:
            return inferAttackPresentation(properties);
        case CARD_TYPES.POWER:
            return {
                card_visual_profile: "power",
                card_play_sfx: "card_power",
                card_impact_vfx: "power_aura",
                card_screen_shake: "",
                card_hit_pause: 0.025,
            };
        case CARD_TYPES.CURSE:
            return {
                card_visual_profile: "curse",
                card_play_sfx: "card_skill",
                card_impact_vfx: "skill_spark",
                card_screen_shake: "",
                card_hit_pause: 0,
            };
        case CARD_TYPES.SKILL:
        default:
            return inferSkillPresentation(properties);
    }
}

function inferAttackPresentation(properties) {
    const heavyAttack = isHeavyAttack(properties);
    return {
        card_visual_profile: "attack",
        card_play_sfx: heavyAttack ? "card_attack_heavy" : "card_attack",
        card_impact_vfx: heavyAttack ? "impact_heavy" : "impact_slash",
        card_screen_shake: heavyAttack ? "medium" : "small",
        card_hit_pause: heavyAttack ? 0.055 : 0.035,
    };
}

function inferSkillPresentation(properties) {
    if (cardHasAction(properties, "ActionAddHealth.gd")) {
        return skillPresentation("card_skill_heal", "heal_burst", "", 0);
    }
    if (cardHasAction(properties, "ActionAddConsumable.gd")) {
        return skillPresentation("card_skill_item", "item_spark", "", 0);
    }
    if (
        cardHasAction(properties, "ActionAddEnergy.gd")
        || (!hasPlayActions(properties) && cardHasAnyAction(properties, ["ActionAddEnergy.gd"]))
    ) {
        return skillPresentation("card_energy", "energy_surge", "", 0);
    }
    if (cardHasAction(properties, "ActionApplyStatus.gd")) {
        return skillPresentation("card_status", "status_burst", "small", 0.025);
    }
    if (cardHasAction(properties, "ActionBlock.gd")) {
        return skillPresentation("card_skill_guard", "guard_burst", "", 0);
    }
    if (cardHasAnyAction(properties, [
        "ActionCreateCards.gd",
        "ActionDrawGenerator.gd",
        "ActionPickCards.gd",
        "ActionPickUpgradeCards.gd",
        "ActionReshuffle.gd",
    ])) {
        return skillPresentation("card_skill_draw", "card_flow", "", 0);
    }
    return skillPresentation("card_skill", "skill_spark", "", 0);
}

function skillPresentation(playSfx, impactVfx, screenShake, hitPause) {
    return {
        card_visual_profile: "skill",
        card_play_sfx: playSfx,
        card_impact_vfx: impactVfx,
        card_screen_shake: screenShake,
        card_hit_pause: hitPause,
    };
}

function cardHasAction(properties, actionName) {
    return getActionPaths(properties, ["card_play_actions"]).some((actionPath) => actionPath.endsWith(actionName));
}

function hasPlayActions(properties) {
    const playActions = properties.card_play_actions;
    return Array.isArray(playActions) && playActions.length > 0;
}

function cardHasAnyAction(properties, actionNames) {
    return getActionPaths(properties, ACTION_ARRAY_FIELDS).some((actionPath) => {
        return actionNames.some((actionName) => actionPath.endsWith(actionName));
    });
}

function getActionPaths(properties, actionArrayFields) {
    const paths = [];
    for (const fieldName of actionArrayFields) {
        const actionArray = properties[fieldName];
        if (!Array.isArray(actionArray)) {
            continue;
        }
        for (const actionEntry of actionArray) {
            if (actionEntry == null || typeof actionEntry !== "object" || Array.isArray(actionEntry)) {
                continue;
            }
            paths.push(...Object.keys(actionEntry));
        }
    }
    return paths;
}

function isHeavyAttack(properties) {
    if (properties.card_type !== CARD_TYPES.ATTACK) {
        return false;
    }
    if (properties.card_energy_cost_is_variable || Number(properties.card_energy_cost || 0) >= 2) {
        return true;
    }
    return getTotalDamageEstimate(properties) >= 12;
}

function getTotalDamageEstimate(properties) {
    const values = properties.card_values || {};
    const damage = numericValue(values.damage, 0);
    const attackCount = Math.max(1, numericValue(values.number_of_attacks, 1));
    return damage * attackCount;
}

function numericValue(value, fallback) {
    return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

main();
