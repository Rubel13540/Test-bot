#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

commit() {
  git add -A
  git commit -m "$1" --allow-empty 2>/dev/null || git commit -m "$1"
}

# 1
cat > package.json <<'EOF'
{
  "name": "fifa-world-cup-2026-prediction-agent",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "description": "AI-powered FIFA World Cup 2026 match and tournament prediction agent",
  "scripts": {
    "build": "tsc -p tsconfig.lib.json",
    "typecheck": "tsc -p tsconfig.json",
    "predict": "tsx src/cli/main.ts",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "devDependencies": {
    "@types/node": "^22.10.0",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2",
    "vitest": "^2.1.6"
  },
  "dependencies": {
    "chalk": "^5.4.1",
    "csv-parse": "^5.6.0",
    "undici": "^7.3.0"
  }
}
EOF
commit "chore: initialize TypeScript project with package.json"

# 2
cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "strict": true,
    "skipLibCheck": true,
    "noEmit": true,
    "verbatimModuleSyntax": false,
    "isolatedModules": true,
    "esModuleInterop": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*.ts", "tests/**/*.test.ts"],
  "exclude": ["node_modules", "dist-lib"]
}
EOF
commit "chore: add TypeScript compiler configuration"

# 3
cat > .gitignore <<'EOF'
node_modules/
dist-lib/
coverage/
.env
.env.*
.DS_Store
.idea/
package-lock.json
EOF
commit "chore: add gitignore for Node and environment files"

# 4
cat > vitest.config.ts <<'EOF'
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: false,
    include: ["tests/**/*.test.ts"],
    environment: "node",
  },
});
EOF
commit "chore: configure vitest test runner"

# 5
mkdir -p src/types
cat > src/types/team.ts <<'EOF'
export interface Team {
  id: string;
  name: string;
  code: string;
  fifaRank: number;
  confederation: "UEFA" | "CONMEBOL" | "CONCACAF" | "CAF" | "AFC" | "OFC";
  eloRating: number;
  isHost?: boolean;
}

export interface SquadPlayer {
  name: string;
  position: "GK" | "DEF" | "MID" | "FWD";
  club: string;
  marketValue: number;
}
EOF
commit "feat: add Team and SquadPlayer type definitions"

# 6
cat > src/types/match.ts <<'EOF'
export type MatchStage =
  | "group"
  | "round-of-32"
  | "round-of-16"
  | "quarter-final"
  | "semi-final"
  | "third-place"
  | "final";

export interface MatchFixture {
  id: string;
  stage: MatchStage;
  group?: string;
  homeTeamId: string;
  awayTeamId: string;
  venueId: string;
  kickoff: string;
  homeScore?: number;
  awayScore?: number;
}

export interface MatchResult {
  homeGoals: number;
  awayGoals: number;
  winnerId: string | null;
  isDraw: boolean;
}
EOF
commit "feat: add MatchFixture and MatchResult types"

# 7
cat > src/types/prediction.ts <<'EOF'
export interface MatchPrediction {
  matchId: string;
  homeWinProb: number;
  drawProb: number;
  awayWinProb: number;
  expectedHomeGoals: number;
  expectedAwayGoals: number;
  confidence: number;
  model: string;
}

export interface TournamentPrediction {
  championId: string;
  championProb: number;
  semifinalists: string[];
  topScorer: string;
  groupWinners: Record<string, string>;
}

export interface ValueBet {
  matchId: string;
  outcome: "home" | "draw" | "away";
  modelProb: number;
  marketProb: number;
  edge: number;
  kellyFraction: number;
}
EOF
commit "feat: add prediction and value bet type definitions"

# 8
cat > src/constants.ts <<'EOF'
export const WC2026_HOSTS = ["USA", "MEX", "CAN"] as const;
export const GROUP_COUNT = 12;
export const TEAMS_PER_GROUP = 4;
export const TOTAL_TEAMS = 48;
export const KNOCKOUT_START_TEAMS = 32;

export const ELO_HOME_ADVANTAGE = 65;
export const ELO_K_FACTOR = 32;
export const POISSON_MAX_GOALS = 8;

export const MODEL_WEIGHTS = {
  elo: 0.35,
  poisson: 0.30,
  form: 0.20,
  squad: 0.15,
} as const;
EOF
commit "feat: add World Cup 2026 tournament constants"

# 9
mkdir -p src/data
cat > src/data/teams.ts <<'EOF'
import type { Team } from "../types/team.js";

export const TEAMS: Team[] = [
  { id: "usa", name: "United States", code: "USA", fifaRank: 11, confederation: "CONCACAF", eloRating: 1780, isHost: true },
  { id: "mex", name: "Mexico", code: "MEX", fifaRank: 14, confederation: "CONCACAF", eloRating: 1765, isHost: true },
  { id: "can", name: "Canada", code: "CAN", fifaRank: 41, confederation: "CONCACAF", eloRating: 1680, isHost: true },
  { id: "arg", name: "Argentina", code: "ARG", fifaRank: 1, confederation: "CONMEBOL", eloRating: 1985 },
  { id: "fra", name: "France", code: "FRA", fifaRank: 2, confederation: "UEFA", eloRating: 1960 },
  { id: "bra", name: "Brazil", code: "BRA", fifaRank: 3, confederation: "CONMEBOL", eloRating: 1945 },
  { id: "eng", name: "England", code: "ENG", fifaRank: 4, confederation: "UEFA", eloRating: 1920 },
  { id: "esp", name: "Spain", code: "ESP", fifaRank: 5, confederation: "UEFA", eloRating: 1910 },
  { id: "ger", name: "Germany", code: "GER", fifaRank: 6, confederation: "UEFA", eloRating: 1895 },
  { id: "por", name: "Portugal", code: "POR", fifaRank: 7, confederation: "UEFA", eloRating: 1885 },
  { id: "ned", name: "Netherlands", code: "NED", fifaRank: 8, confederation: "UEFA", eloRating: 1875 },
  { id: "bel", name: "Belgium", code: "BEL", fifaRank: 9, confederation: "UEFA", eloRating: 1865 },
  { id: "ita", name: "Italy", code: "ITA", fifaRank: 10, confederation: "UEFA", eloRating: 1855 },
  { id: "cro", name: "Croatia", code: "CRO", fifaRank: 12, confederation: "UEFA", eloRating: 1840 },
  { id: "uru", name: "Uruguay", code: "URU", fifaRank: 13, confederation: "CONMEBOL", eloRating: 1835 },
  { id: "mar", name: "Morocco", code: "MAR", fifaRank: 15, confederation: "CAF", eloRating: 1820 },
  { id: "col", name: "Colombia", code: "COL", fifaRank: 16, confederation: "CONMEBOL", eloRating: 1815 },
  { id: "jpn", name: "Japan", code: "JPN", fifaRank: 17, confederation: "AFC", eloRating: 1805 },
  { id: "sui", name: "Switzerland", code: "SUI", fifaRank: 18, confederation: "UEFA", eloRating: 1800 },
  { id: "sen", name: "Senegal", code: "SEN", fifaRank: 19, confederation: "CAF", eloRating: 1795 },
  { id: "irn", name: "Iran", code: "IRN", fifaRank: 20, confederation: "AFC", eloRating: 1790 },
  { id: "den", name: "Denmark", code: "DEN", fifaRank: 21, confederation: "UEFA", eloRating: 1785 },
  { id: "kor", name: "South Korea", code: "KOR", fifaRank: 22, confederation: "AFC", eloRating: 1775 },
  { id: "aus", name: "Australia", code: "AUS", fifaRank: 23, confederation: "AFC", eloRating: 1770 },
];

export function getTeamById(id: string): Team | undefined {
  return TEAMS.find((t) => t.id === id);
}

export function getTeamByCode(code: string): Team | undefined {
  return TEAMS.find((t) => t.code === code);
}
EOF
commit "feat: add World Cup 2026 team roster with Elo ratings"

# 10
cat > src/data/groups.ts <<'EOF'
export interface GroupAssignment {
  group: string;
  teamIds: string[];
}

export const GROUPS: GroupAssignment[] = [
  { group: "A", teamIds: ["usa", "mex", "col", "sen"] },
  { group: "B", teamIds: ["arg", "bra", "jpn", "aus"] },
  { group: "C", teamIds: ["fra", "mar", "kor", "can"] },
  { group: "D", teamIds: ["eng", "ger", "uru", "irn"] },
  { group: "E", teamIds: ["esp", "por", "cro", "sui"] },
  { group: "F", teamIds: ["ned", "bel", "ita", "den"] },
];

export function getGroupForTeam(teamId: string): string | undefined {
  return GROUPS.find((g) => g.teamIds.includes(teamId))?.group;
}
EOF
commit "feat: add group stage draw assignments"

# 11
cat > src/data/venues.ts <<'EOF'
export interface Venue {
  id: string;
  name: string;
  city: string;
  country: "USA" | "MEX" | "CAN";
  capacity: number;
  altitude: number;
}

export const VENUES: Venue[] = [
  { id: "metlife", name: "MetLife Stadium", city: "East Rutherford", country: "USA", capacity: 82500, altitude: 3 },
  { id: "sofi", name: "SoFi Stadium", city: "Inglewood", country: "USA", capacity: 70000, altitude: 30 },
  { id: "att", name: "AT&T Stadium", city: "Arlington", country: "USA", capacity: 80000, altitude: 180 },
  { id: "azteca", name: "Estadio Azteca", city: "Mexico City", country: "MEX", capacity: 87000, altitude: 2240 },
  { id: "bbva", name: "Estadio BBVA", city: "Monterrey", country: "MEX", capacity: 53500, altitude: 540 },
  { id: "bmo", name: "BMO Field", city: "Toronto", country: "CAN", capacity: 45000, altitude: 75 },
];

export function getVenueById(id: string): Venue | undefined {
  return VENUES.find((v) => v.id === id);
}
EOF
commit "feat: add host city venues with altitude data"

# 12
cat > src/data/fixtures.ts <<'EOF'
import type { MatchFixture } from "../types/match.js";

export const GROUP_FIXTURES: MatchFixture[] = [
  { id: "A1", stage: "group", group: "A", homeTeamId: "usa", awayTeamId: "sen", venueId: "metlife", kickoff: "2026-06-11T20:00:00Z" },
  { id: "A2", stage: "group", group: "A", homeTeamId: "mex", awayTeamId: "col", venueId: "azteca", kickoff: "2026-06-12T02:00:00Z" },
  { id: "B1", stage: "group", group: "B", homeTeamId: "arg", awayTeamId: "aus", venueId: "sofi", kickoff: "2026-06-13T00:00:00Z" },
  { id: "B2", stage: "group", group: "B", homeTeamId: "bra", awayTeamId: "jpn", venueId: "att", kickoff: "2026-06-13T20:00:00Z" },
  { id: "C1", stage: "group", group: "C", homeTeamId: "fra", awayTeamId: "can", venueId: "bmo", kickoff: "2026-06-14T18:00:00Z" },
  { id: "C2", stage: "group", group: "C", homeTeamId: "mar", awayTeamId: "kor", venueId: "metlife", kickoff: "2026-06-15T00:00:00Z" },
  { id: "D1", stage: "group", group: "D", homeTeamId: "eng", awayTeamId: "irn", venueId: "sofi", kickoff: "2026-06-15T20:00:00Z" },
  { id: "D2", stage: "group", group: "D", homeTeamId: "ger", awayTeamId: "uru", venueId: "att", kickoff: "2026-06-16T02:00:00Z" },
  { id: "E1", stage: "group", group: "E", homeTeamId: "esp", awayTeamId: "sui", venueId: "bbva", kickoff: "2026-06-16T20:00:00Z" },
  { id: "E2", stage: "group", group: "E", homeTeamId: "por", awayTeamId: "cro", venueId: "azteca", kickoff: "2026-06-17T02:00:00Z" },
  { id: "F1", stage: "group", group: "F", homeTeamId: "ned", awayTeamId: "den", venueId: "bmo", kickoff: "2026-06-17T20:00:00Z" },
  { id: "F2", stage: "group", group: "F", homeTeamId: "bel", awayTeamId: "ita", venueId: "metlife", kickoff: "2026-06-18T02:00:00Z" },
];

export function getFixturesByGroup(group: string): MatchFixture[] {
  return GROUP_FIXTURES.filter((f) => f.group === group);
}
EOF
commit "feat: add opening group stage match fixtures"

# 13
mkdir -p src/models
cat > src/models/elo.ts <<'EOF'
import { ELO_HOME_ADVANTAGE, ELO_K_FACTOR } from "../constants.js";

export function expectedScore(ratingA: number, ratingB: number): number {
  return 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
}

export function winDrawLossProbs(
  homeElo: number,
  awayElo: number,
  homeAdvantage = ELO_HOME_ADVANTAGE
): { home: number; draw: number; away: number } {
  const adjustedHome = homeElo + homeAdvantage;
  const homeWin = expectedScore(adjustedHome, awayElo);
  const awayWin = expectedScore(awayElo, adjustedHome);
  const draw = 1 - homeWin - awayWin;
  const drawClamped = Math.max(0.15, Math.min(0.35, draw));
  const remaining = 1 - drawClamped;
  const total = homeWin + awayWin;
  return {
    home: remaining * (homeWin / total),
    draw: drawClamped,
    away: remaining * (awayWin / total),
  };
}

export function updateElo(
  winnerElo: number,
  loserElo: number,
  isDraw: boolean,
  k = ELO_K_FACTOR
): { winnerNew: number; loserNew: number } {
  const expected = expectedScore(winnerElo, loserElo);
  const actual = isDraw ? 0.5 : 1;
  const delta = k * (actual - expected);
  return { winnerNew: winnerElo + delta, loserNew: loserElo - delta };
}
EOF
commit "feat: implement Elo rating win probability model"

# 14
cat > src/models/poisson.ts <<'EOF'
import { POISSON_MAX_GOALS } from "../constants.js";

function factorial(n: number): number {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}

export function poissonPmf(k: number, lambda: number): number {
  return (Math.pow(lambda, k) * Math.exp(-lambda)) / factorial(k);
}

export function scoreMatrix(
  homeLambda: number,
  awayLambda: number,
  maxGoals = POISSON_MAX_GOALS
): number[][] {
  const matrix: number[][] = [];
  for (let h = 0; h <= maxGoals; h++) {
    matrix[h] = [];
    for (let a = 0; a <= maxGoals; a++) {
      matrix[h][a] = poissonPmf(h, homeLambda) * poissonPmf(a, awayLambda);
    }
  }
  return matrix;
}

export function outcomeProbsFromMatrix(matrix: number[][]): {
  home: number;
  draw: number;
  away: number;
} {
  let home = 0, draw = 0, away = 0;
  for (let h = 0; h < matrix.length; h++) {
    for (let a = 0; a < matrix[h].length; a++) {
      const p = matrix[h][a];
      if (h > a) home += p;
      else if (h === a) draw += p;
      else away += p;
    }
  }
  return { home, draw, away };
}

export function expectedGoals(attack: number, defense: number, leagueAvg = 1.35): number {
  return Math.max(0.3, attack * defense * leagueAvg);
}
EOF
commit "feat: implement Poisson distribution goal model"

# 15
cat > src/models/formScore.ts <<'EOF'
export interface RecentResult {
  opponentId: string;
  goalsFor: number;
  goalsAgainst: number;
  isHome: boolean;
}

export function calculateFormScore(results: RecentResult[], window = 5): number {
  if (results.length === 0) return 0.5;
  const recent = results.slice(-window);
  let points = 0;
  for (const r of recent) {
    if (r.goalsFor > r.goalsAgainst) points += 3;
    else if (r.goalsFor === r.goalsAgainst) points += 1;
  }
  const maxPoints = recent.length * 3;
  return maxPoints > 0 ? points / maxPoints : 0.5;
}

export function attackDefenseFromForm(
  results: RecentResult[]
): { attack: number; defense: number } {
  if (results.length === 0) return { attack: 1, defense: 1 };
  const goalsFor = results.reduce((s, r) => s + r.goalsFor, 0) / results.length;
  const goalsAgainst = results.reduce((s, r) => s + r.goalsAgainst, 0) / results.length;
  return {
    attack: Math.max(0.5, goalsFor / 1.35),
    defense: Math.max(0.5, 1.35 / Math.max(0.5, goalsAgainst)),
  };
}
EOF
commit "feat: add recent form score calculator"

# 16
cat > src/models/ensemble.ts <<'EOF'
import { MODEL_WEIGHTS } from "../constants.js";

export interface ModelOutput {
  home: number;
  draw: number;
  away: number;
  expectedHomeGoals?: number;
  expectedAwayGoals?: number;
}

export function ensemblePredict(outputs: {
  elo: ModelOutput;
  poisson: ModelOutput;
  form: ModelOutput;
  squad?: ModelOutput;
}): ModelOutput {
  const w = MODEL_WEIGHTS;
  const squad = outputs.squad ?? { home: 0.33, draw: 0.34, away: 0.33 };
  const squadWeight = outputs.squad ? w.squad : 0;
  const totalWeight = w.elo + w.poisson + w.form + squadWeight;
  const norm = (v: number) => v / totalWeight;

  const home =
    norm(w.elo) * outputs.elo.home +
    norm(w.poisson) * outputs.poisson.home +
    norm(w.form) * outputs.form.home +
    norm(squadWeight) * squad.home;

  const draw =
    norm(w.elo) * outputs.elo.draw +
    norm(w.poisson) * outputs.poisson.draw +
    norm(w.form) * outputs.form.draw +
    norm(squadWeight) * squad.draw;

  const away =
    norm(w.elo) * outputs.elo.away +
    norm(w.poisson) * outputs.poisson.away +
    norm(w.form) * outputs.form.away +
    norm(squadWeight) * squad.away;

  return {
    home,
    draw,
    away,
    expectedHomeGoals: outputs.poisson.expectedHomeGoals,
    expectedAwayGoals: outputs.poisson.expectedAwayGoals,
  };
}
EOF
commit "feat: add weighted ensemble prediction combiner"

# 17
mkdir -p src/predictions
cat > src/predictions/confidence.ts <<'EOF'
export function calculateConfidence(
  modelAgreement: number,
  dataQuality: number,
  sampleSize: number
): number {
  const sampleFactor = Math.min(1, sampleSize / 10);
  const raw = 0.5 * modelAgreement + 0.3 * dataQuality + 0.2 * sampleFactor;
  return Math.round(Math.min(0.95, Math.max(0.1, raw)) * 100) / 100;
}

export function modelAgreement(probs: number[][]): number {
  if (probs.length < 2) return 0.5;
  const outcomes = ["home", "draw", "away"] as const;
  let agreement = 0;
  for (let i = 0; i < 3; i++) {
    const values = probs.map((p) => p[i]);
    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    const variance = values.reduce((s, v) => s + Math.pow(v - mean, 2), 0) / values.length;
    agreement += 1 - Math.min(1, variance * 10);
  }
  return agreement / 3;
}
EOF
commit "feat: add prediction confidence scoring"

# 18
cat > src/predictions/matchPredictor.ts <<'EOF'
import { getTeamById } from "../data/teams.js";
import { winDrawLossProbs } from "../models/elo.js";
import { expectedGoals, outcomeProbsFromMatrix, scoreMatrix } from "../models/poisson.js";
import { attackDefenseFromForm, calculateFormScore, type RecentResult } from "../models/formScore.js";
import { ensemblePredict } from "../models/ensemble.js";
import { calculateConfidence, modelAgreement } from "./confidence.js";
import type { MatchFixture } from "../types/match.js";
import type { MatchPrediction } from "../types/prediction.js";

export interface PredictorInput {
  fixture: MatchFixture;
  homeForm?: RecentResult[];
  awayForm?: RecentResult[];
}

export function predictMatch(input: PredictorInput): MatchPrediction {
  const home = getTeamById(input.fixture.homeTeamId);
  const away = getTeamById(input.fixture.awayTeamId);
  if (!home || !away) throw new Error(`Unknown team in fixture ${input.fixture.id}`);

  const elo = winDrawLossProbs(home.eloRating, away.eloRating, home.isHost ? 80 : 65);
  const homeAD = attackDefenseFromForm(input.homeForm ?? []);
  const awayAD = attackDefenseFromForm(input.awayForm ?? []);
  const homeLambda = expectedGoals(homeAD.attack, awayAD.defense);
  const awayLambda = expectedGoals(awayAD.attack, homeAD.defense);
  const matrix = scoreMatrix(homeLambda, awayLambda);
  const poisson = outcomeProbsFromMatrix(matrix);
  poisson.expectedHomeGoals = homeLambda;
  poisson.expectedAwayGoals = awayLambda;

  const homeFormScore = calculateFormScore(input.homeForm ?? []);
  const awayFormScore = calculateFormScore(input.awayForm ?? []);
  const formTotal = homeFormScore + awayFormScore || 1;
  const form = {
    home: homeFormScore / formTotal * 0.7 + 0.15,
    away: awayFormScore / formTotal * 0.7 + 0.15,
    draw: 0.2,
  };

  const ensemble = ensemblePredict({ elo, poisson, form });
  const agreement = modelAgreement([
    [elo.home, elo.draw, elo.away],
    [poisson.home, poisson.draw, poisson.away],
    [form.home, form.draw, form.away],
  ]);

  return {
    matchId: input.fixture.id,
    homeWinProb: Math.round(ensemble.home * 1000) / 1000,
    drawProb: Math.round(ensemble.draw * 1000) / 1000,
    awayWinProb: Math.round(ensemble.away * 1000) / 1000,
    expectedHomeGoals: Math.round((ensemble.expectedHomeGoals ?? homeLambda) * 100) / 100,
    expectedAwayGoals: Math.round((ensemble.expectedAwayGoals ?? awayLambda) * 100) / 100,
    confidence: calculateConfidence(agreement, 0.8, (input.homeForm?.length ?? 0) + (input.awayForm?.length ?? 0)),
    model: "ensemble-v1",
  };
}
EOF
commit "feat: implement match-level ensemble predictor"

# 19
cat > src/predictions/tournamentPredictor.ts <<'EOF'
import { GROUPS } from "../data/groups.js";
import { GROUP_FIXTURES } from "../data/fixtures.js";
import { predictMatch } from "./matchPredictor.js";
import type { TournamentPrediction } from "../types/prediction.js";

export interface GroupStanding {
  teamId: string;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  goalsFor: number;
  goalsAgainst: number;
  points: number;
}

export function simulateGroupStandings(): Record<string, GroupStanding[]> {
  const standings: Record<string, GroupStanding[]> = {};
  for (const group of GROUPS) {
    standings[group.group] = group.teamIds.map((id) => ({
      teamId: id, play
