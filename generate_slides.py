#!/usr/bin/env python3
"""Generate presentation PDF using fpdf2 with DejaVu Unicode font."""
from fpdf import FPDF
import os

FONT_DIR = '/usr/share/fonts/truetype/dejavu'

class SlideDeck(FPDF):
    def __init__(self):
        super().__init__('LANDSCAPE', 'mm', (254, 190.5))  # 10x7.5"
        self.set_auto_page_break(False)
        self.add_font('DJ', '', f'{FONT_DIR}/DejaVuSans.ttf')
        self.add_font('DJ', 'B', f'{FONT_DIR}/DejaVuSans-Bold.ttf')
        # self.add_font('DJ', '', ...) - no oblique available
        
    def header(self):
        pass
    
    def footer(self):
        self.set_y(-10)
        self.set_font('DJ', '', 7)
        self.set_text_color(160,160,160)
        self.cell(0, 8, str(self.page_no()), align='R')
    
    def slide_title(self, txt):
        self.set_font('DJ', 'B', 24)
        self.set_text_color(255,255,255)
        self.set_xy(15, 35)
        self.multi_cell(224, 12, txt, align='C')
    
    def slide_subtitle(self, txt):
        self.set_font('DJ', '', 13)
        self.set_text_color(190,190,210)
        self.set_xy(15, 65)
        self.multi_cell(224, 8, txt, align='C')
    
    def slide_author(self, txt):
        self.set_font('DJ', '', 11)
        self.set_text_color(160,160,180)
        self.set_xy(15, 120)
        self.multi_cell(224, 7, txt, align='C')
    
    def title_slide(self, title, subtitle, author):
        self.add_page()
        self.set_fill_color(25, 26, 46)
        self.rect(0, 0, 254, 190.5, 'F')
        self.slide_title(title)
        self.slide_subtitle(subtitle)
        self.slide_author(author)

    def slide_start(self, title, color=(46,134,171)):
        self.add_page()
        self.set_fill_color(*color)
        self.rect(0, 0, 254, 32, 'F')
        self.set_text_color(255,255,255)
        self.set_font('DJ', 'B', 16)
        self.set_xy(15, 8)
        self.cell(224, 16, title)
        return 40
    
    def bullet(self, text, bold=False, y=0):
        font = 'DJ', 'B' if bold else '', 10
        self.set_font(*font)
        self.set_text_color(40,40,40)
        self.set_xy(18, y)
        self.multi_cell(218, 6, text)
        return y + 6 * max(1, len(text)//60 + (1 if len(text)>60 else 0)) + 2

    def section_slide(self, title):
        self.add_page()
        self.set_fill_color(46, 134, 171)
        self.rect(0, 0, 254, 190.5, 'F')
        self.set_text_color(255,255,255)
        self.set_font('DJ', 'B', 22)
        self.set_xy(15, 80)
        self.multi_cell(224, 12, title, align='C')

pdf = SlideDeck()

# === Slide 1: Title ===
pdf.title_slide(
    'From Concept to Submission in 8 Hours',
    'An Agentic Research Workflow: Ridge-Cal, Digital Twins,\nand the Birth of a Statistical Research Skill',
    'Yue Shentu  |  May 18, 2026'
)

# === Slide 2: The Spark ===
pdf.section_slide('The Spark: What Started This')

y = pdf.slide_start('The Problem')
y = pdf.bullet('PROCOVA is EMA-qualified for improving trial efficiency via prognostic scores', y=y)
y = pdf.bullet('But it assumes the external score is perfectly calibrated for the trial population', y=y)
y = pdf.bullet('Population shift is the rule, not the exception - especially in oncology', y=y)
y = pdf.bullet('No existing method diagnoses or corrects miscalibration using blinded data', y=y)
y = y + 4
y = pdf.bullet('The Ridge-Cal Idea:', bold=True, y=y)
y = pdf.bullet('Diagnose: compare C-index of score vs score + calibration covariates', y=y)
y = pdf.bullet('Calibrate: ridge-penalized Cox on blinded data, lambda by CV', y=y)
y = pdf.bullet('Analyze: standard Cox PH with calibrated score + robust sandwich SE', y=y)
pdf.bullet('6 parameters, blinded data, no new data collection needed', y=y)

# === Slide 3: Timeline ===
pdf.section_slide('The 8-Hour Journey')

y = pdf.slide_start('Timeline: May 17-18, 2026')
timeline = [
    ('~21:00', 'Initial concept: TMLE + Bayesian MCMC (too complex)'),
    ('~22:00', 'Pivot to ridge regression on 5 covariates'),
    ('~23:00', 'First simulation - bug found (non-PH wrong)'),
    ('~00:00', '10K-rep simulation running'),
    ('~01:00', 'MAP-Cox bug found (k applied after pooling)'),
    ('~06:00', 'Manuscript drafted, code audit done'),
    ('~07:00', 'Reviewer 2 (Gemini): Major Revision - 7 point fixes'),
    ('~08:00', 'Revised, Qwen review: Major -> Minor -> Accept'),
    ('~09:00', 'Digital twin landscape report for SVPs'),
    ('~10:00', 'JBS formatting, Liberation Serif, all checks pass'),
    ('~14:00', 'Small strata investigation: voice note -> white paper'),
    ('~15:00', 'Skill refined, presentation ready'),
]
for time, event in timeline:
    pdf.set_font('DJ', 'B', 8); pdf.set_text_color(46,134,171)
    pdf.set_xy(18, y); pdf.cell(22, 5, time)
    pdf.set_font('DJ', '', 8); pdf.set_text_color(60,60,60)
    pdf.cell(200, 5, event)
    y += 5.5

# === Slide 4: Deliverables ===
y = pdf.slide_start('What Got Built')
y = pdf.bullet('Deliverables:', bold=True, y=y)
y = pdf.bullet('Ridge-Cal manuscript (12 pages) - submission-ready for JBS', y=y)
y = pdf.bullet('Response to Reviewer 2 - point-by-point rebuttal', y=y)
y = pdf.bullet('Digital twin landscape survey (12 pages, 3 diagrams) - for SVPs', y=y)
y = pdf.bullet('Small strata white paper with SAP language recommendations', y=y)
y = pdf.bullet('Statistical Research Workflow skill (SKILL.md)', y=y)
y = pdf.bullet('All simulation code and results on GitHub (public repos)', y=y)
y = y + 3
y = pdf.bullet('Tools Used:', bold=True, y=y)
y = pdf.bullet('R + glmnet + furrr (simulations) | Python + matplotlib (diagrams)', y=y)
y = pdf.bullet('Whisper (transcription) | Pandoc + LaTeX (PDF generation)', y=y)
y = pdf.bullet('DeepSeek (writer) | Qwen (reviewer) | Gemini Pro (external review)', y=y)

# === Slide 5: Multi-Model Review ===
pdf.section_slide('The Multi-Model Review Loop')
y = pdf.slide_start('Why One AI Isnt Enough')
y = pdf.bullet('Same-model reviewers share the same blind spots and hallucination patterns', y=y)
y = y + 3
y = pdf.bullet('Internal Loop (OpenClaw, essentially free):', bold=True, y=y)
y = pdf.bullet('Writer: DeepSeek v4 Flash | Reviewer: Qwen (different architecture)', y=y)
y = pdf.bullet('Caught: Section 4 redundancy, delta justification, missing data, table headers', y=y)
y = y + 3
y = pdf.bullet('External Loop (separate AI platform):', bold=True, y=y)
y = pdf.bullet('Reviewer: Gemini Pro (different company, different training)', y=y)
y = pdf.bullet('Caught: Non-collapsibility, tone, event rates, LoRA framing', y=y)

# === Slide 6: Convergence ===
y = pdf.slide_start('The Convergence', color=(25,26,46))
pdf.set_text_color(220,220,230)
y = pdf.bullet('Gemini: Major Revision -> Accept (1 round, 4 issues)', y=y)
y = pdf.bullet('Qwen: Major -> Minor -> Accept (3 rounds, 7 DIFFERENT issues)', y=y)
y = pdf.bullet('Total: 11 distinct bugs caught by 2 different AI models', y=y)
y = y + 5
y = pdf.bullet('Key Insight:', bold=True, y=y)
y = pdf.bullet('Qwen caught issues Gemini COMPLETELY MISSED:', y=y)
y = pdf.bullet('Section 4 redundancy, delta = 0.01 justification, table header ambiguity', y=y)
y = pdf.bullet('MAP-Cox unfair comparison framing, sandwich variance scope', y=y)
y = pdf.bullet('Missing data acknowledgment, reference formatting', y=y)
y = pdf.bullet('This validates model-diverse review', y=y)

# === Slide 7: Demo ===
pdf.section_slide('The Demo: Voice Note to White Paper in 10 Minutes')
y = pdf.slide_start('The Small Strata Investigation')
y = pdf.bullet('Input: Voice note while driving', bold=True, y=y)
y = pdf.bullet('"Do we need to pool small strata for CMH OR/RR and MN RD methods?"', y=y)
y = pdf.bullet('Transcribed by Whisper (tiny model, <1 min)', y=y)
y = y + 3
steps = [
    ('Step 1 (1m)', 'Problem scoping - Phase 0 research proposal'),
    ('Step 2 (1m)', 'Independent review - Qwen (isolated) -> Weak'),
    ('Step 3 (1m)', 'Revision - reframed as internal white paper'),
    ('Step 4 (3m)', 'Code + 5K-rep simulation with block randomization'),
    ('Step 5 (1m)', 'Code review v1 - caught 3 bugs (Scenario 4, RR var, Wald vs MN)'),
    ('Step 6 (1m)', 'Code review v2 - verified fixes'),
    ('Step 7 (1m)', 'Final review - white paper + code consistency'),
    ('Step 8 (<1m)', 'Push to public GitHub repo'),
]
for step, desc in steps:
    pdf.set_font('DJ', 'B', 8); pdf.set_text_color(46,134,171)
    pdf.set_xy(18, y); pdf.cell(28, 5, step)
    pdf.set_font('DJ', '', 8); pdf.set_text_color(60,60,60)
    pdf.cell(195, 5, desc)
    y += 5.5

# === Slide 8: Results ===
pdf.slide_start('Small Strata Results')
h = ['Method', 'Failure Rate', 'Type I', 'Pooling?']
rows = [
    ['CMH OR (+0.5 CC)', '0.000', '0.043-0.054', 'No'],
    ['CMH RR (GR var)', '0.000', '0.045-0.081', 'No (inherent)'],
    ['Stratified MN RD', '0.000', '0.035-0.069', 'No'],
    ['Cox PH (stratified)', 'N/A', 'N/A', 'No'],
    ['Log-rank (stratified)', 'N/A', 'N/A', 'No'],
]
col_w = 210 / len(h)
x0 = 22
pdf.set_fill_color(46,134,171); pdf.set_text_color(255,255,255)
pdf.set_font('DJ', 'B', 9)
pdf.set_xy(x0, 42)
for i, hd in enumerate(h):
    pdf.cell(col_w, 8, hd, border=1, fill=True, align='C')
pdf.set_text_color(40,40,40); pdf.set_font('DJ', '', 8)
for ri, row in enumerate(rows):
    y = 50 + ri * 7
    pdf.set_xy(x0, y)
    for ci, cell in enumerate(row):
        pdf.cell(col_w, 7, str(cell), border=1, align='C')

y2 = 50 + len(rows) * 7 + 10
pdf.set_text_color(60,60,60); pdf.set_font('DJ', '', 8)
pdf.set_xy(22, y2); pdf.multi_cell(210, 5,
    'Conclusion: No pooling required for any method. '
    'Type I inflation is inherent to the methods, not caused by small strata.')
pdf.set_font('DJ', '', 9); pdf.set_text_color(40,40,40)
y2 = y2 + 18
pdf.set_xy(22, y2)
pdf.cell(210, 6, 'Code reviews caught: Scenario 4 duplicated, RR variance unstratified, Wald mislabeled as MN')

# === Slide 9: Workflow ===
pdf.section_slide('The Emergent Workflow')
y = pdf.slide_start('The Skill File - 8 Phases')
phases = [
    ('Ph 0: Topic ID', 'Identify gap, map contradictory literature'),
    ('Ph 1: Initial Writeup', 'Write, spawn isolated reviewer, iterate'),
    ('Ph 2: Simulation', '2 -> 20 -> 200 -> 10,000 reps (progressive)'),
    ('Ph 3: Multi-Agent QC', 'CODE REVIEW BEFORE BIG RUNS - DO NOT SKIP'),
    ('Ph 4: Full Run', 'Background, cron scheduling, monitoring'),
    ('Ph 4.5: Reproducibility', 'Verify code matches manuscript'),
    ('Ph 5: Manuscript', 'References, PDF self-check, senior review'),
    ('Ph 6: Revision', 'Parse -> Reconcile -> Re-sim -> Diff check'),
    ('Ph 7: Pre-Sub Loop', 'Isolated reviewer -> Revise -> Max 3 rounds'),
]
for phase, desc in phases:
    pdf.set_font('DJ', 'B', 8); pdf.set_text_color(46,134,171)
    pdf.set_xy(18, y); pdf.cell(30, 5, phase)
    pdf.set_font('DJ', '', 8); pdf.set_text_color(60,60,60)
    pdf.cell(190, 5, desc)
    y += 5.5

# === Slide 10: Key Rules ===
y = pdf.slide_start('Key Rules That Emerged')
y = pdf.bullet('Critical Rules (Do Not Skip):', bold=True, y=y)
y = pdf.bullet('1. Isolate reviewers - context="isolated", no discussion history', y=y)
y = pdf.bullet('2. Diversify models - different AIs catch different bugs', y=y)
y = pdf.bullet('3. Code review BEFORE big simulations - never trust your code', y=y)
y = pdf.bullet('4. PDF self-verify - programmatic checks before sending to human', y=y)
y = y + 4
y = pdf.bullet('Process Rules:', bold=True, y=y)
y = pdf.bullet('5. Clean up cruft every iteration - stale labels, comments, files', y=y)
y = pdf.bullet('6. Push to GitHub at milestones - enables external AI/human review', y=y)
y = pdf.bullet('7. Batch deliveries - dont send incremental fixes, pace yourself', y=y)
y = pdf.bullet('8. Commit often, push at checkpoints', y=y)

# === Slide 11: What Went Wrong ===
y = pdf.slide_start('What Went Wrong (And What We Fixed)')
y = pdf.bullet('PDF Verification Disaster:', bold=True, y=y)
y = pdf.bullet('5 failed attempts. Images silently failed (RGBA, code blocks, paths).', y=y)
y = pdf.bullet('Fixed: verify_pdf.py, programmatic checks before every send.', y=y)
y = y + 3
y = pdf.bullet('Skipped Code Review (Initial):', bold=True, y=y)
y = pdf.bullet('Would have delivered buggy simulation results.', y=y)
y = pdf.bullet('Fixed: "DO NOT SKIP" warning in skill, three independent reviews.', y=y)
y = y + 3
y = pdf.bullet('Fast Iteration Exhausted the Human:', bold=True, y=y)
y = pdf.bullet('Too many incremental fixes sent separately.', y=y)
y = pdf.bullet('Fixed: batch changes, let human set the pace.', y=y)
y = y + 3
y = pdf.bullet('Stale Artifacts:', bold=True, y=y)
y = pdf.bullet('Old PDFs, old labels, old comments accumulated.', y=y)
y = pdf.bullet('Fixed: explicit cleanup at every milestone.', y=y)

# === Slide 12: Economics ===
y = pdf.slide_start('The Economics')
y = pdf.bullet('Session Overview (8 hours of active collaboration):', bold=True, y=y)
y = pdf.bullet('DeepSeek API tokens used: ~500K total', y=y)
y = pdf.bullet('Estimated API cost: < $1.00 for the entire session', y=y)
y = y + 4
y = pdf.bullet('What >$1.00 Bought:', bold=True, y=y)
y = pdf.bullet('1 manuscript submission-ready for JBS', y=y)
y = pdf.bullet('1 SVP-ready digital twin report (12 pages, 3 diagrams)', y=y)
y = pdf.bullet('1 complete simulation study with white paper + SAP language', y=y)
y = pdf.bullet('1 research workflow skill file', y=y)
y = pdf.bullet('3 independent AI reviews from 2 different models', y=y)
y = pdf.bullet('3 GitHub repos with full code and documentation', y=y)
y = y + 4
y = pdf.bullet('The Model Gap:', bold=True, y=y)
y = pdf.bullet('DeepSeek v4 Flash: exceptional reasoning for the price', y=y)
y = pdf.bullet('Qwen: thorough, catches structural issues', y=y)
y = pdf.bullet('Gemini Pro: different blind spots, good for external review', y=y)
y = pdf.bullet('Claude Opus: planned addition for senior reviewer perspective', y=y)

# === Slide 13: Thank You ===
pdf.add_page()
pdf.set_fill_color(25, 26, 46)
pdf.rect(0, 0, 254, 190.5, 'F')
pdf.set_text_color(255,255,255)
pdf.set_font('DJ', 'B', 28)
pdf.set_xy(15, 60)
pdf.cell(224, 15, 'Thank You', align='C')
pdf.set_font('DJ', '', 14)
pdf.set_text_color(190,190,210)
pdf.set_xy(15, 85)
pdf.cell(224, 10, 'Questions?', align='C')
pdf.set_font('DJ', '', 9)
pdf.set_text_color(140,140,160)
pdf.set_xy(15, 120)
pdf.multi_cell(224, 6,
    'Repos:  github.com/doublerobust/ridge-cal  |  github.com/doublerobust/small-strata-pooling\n'
    'The skill: SKILL.md in the research workflow - available on request', align='C')

pdf.output('/home/yue-shentu/.openclaw/workspace/research-proposals/talk-slides.pdf')
sz = os.path.getsize('/home/yue-shentu/.openclaw/workspace/research-proposals/talk-slides.pdf')
print(f'OK: talk-slides.pdf ({sz/1024:.0f} KB, {pdf.page_no()} slides)')
