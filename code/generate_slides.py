#!/usr/bin/env python3
"""Generate presentation PDF using fpdf2 with DejaVu Unicode font.
   Yue's perspective, collaborative framing."""
from fpdf import FPDF
import os

FONT_DIR = '/usr/share/fonts/truetype/dejavu'

class SlideDeck(FPDF):
    def __init__(self):
        super().__init__('LANDSCAPE', 'mm', (254, 190.5))  # 10x7.5"
        self.set_auto_page_break(False)
        self.add_font('DJ', '', f'{FONT_DIR}/DejaVuSans.ttf')
        self.add_font('DJ', 'B', f'{FONT_DIR}/DejaVuSans-Bold.ttf')
        
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

# === Slide 2: Tech Stack ===
pdf.section_slide('The Tech Stack Journey')

y = pdf.slide_start('Setting Up the Infrastructure')
y = pdf.bullet('Configured an AI agent as my research assistant, connected via Telegram', y=y)
y = pdf.bullet('Started with local models (LM Studio) - tool calling was unreliable', y=y)
y = pdf.bullet('Switched to DeepSeek API: cheap (~$0.15/M input), fast, reliable tool calling', y=y)
y = pdf.bullet('Added Qwen via Ollama as a second model for independent cross-checking', y=y)
y = pdf.bullet('Integrated Whisper so I could dictate ideas while pacing around the kitchen', y=y)
y = y + 3
y = pdf.bullet('Key Dependencies:', bold=True, y=y)
y = pdf.bullet('R + glmnet/furrr (simulations) | Python + matplotlib (diagrams)', y=y)
y = pdf.bullet('Whisper (transcription) | Pandoc + LaTeX (PDF generation)', y=y)
y = pdf.bullet('Lesson: start with the API that works, optimize later', y=y)

# === Slide 3: The Problem ===
pdf.section_slide('The Spark: Where It Started')

y = pdf.slide_start('The Problem')
y = pdf.bullet('PROCOVA is EMA-qualified for improving trial efficiency via prognostic scores', y=y)
y = pdf.bullet('But it assumes the external score is perfectly calibrated for the trial population', y=y)
y = pdf.bullet('Population shift is the rule, not the exception - especially in oncology', y=y)
y = pdf.bullet('No existing method diagnoses or corrects miscalibration using blinded data', y=y)
y = y + 4
y = pdf.bullet('The Ridge-Cal Idea I Had:', bold=True, y=y)
y = pdf.bullet('Treat the external score as a pre-trained model, apply ridge-penalized Cox correction', y=y)
y = pdf.bullet('Diagnose -> Calibrate -> Analyze. 6 parameters, blinded data, no new data collection', y=y)

# === Slide 4: Timeline ===
pdf.section_slide('The 8-Hour Journey')

y = pdf.slide_start('Timeline: May 17-18, 2026')
timeline = [
    ('~21:00', 'Initial concept brainstorm: TMLE + Bayesian MCMC (too complex, scrapped)'),
    ('~22:00', 'Pivot to ridge regression on 5 covariates'),
    ('~23:00', 'First simulation - agent found a bug (non-PH assumption)'),
    ('~00:00', '10K-rep simulation running'),
    ('~01:00', 'MAP-Cox bug surfaced (k applied after pooling)'),
    ('~02:00', 'Bug fixed, re-simulation triggered'),
    ('~06:00', 'Manuscript drafted - agent wrote prose, I reviewed every section'),
    ('~07:00', 'Sent to Gemini (Reviewer 2) - Major Revision, 4 issues'),
    ('~07:15', 'Agent fixed all 4 issues per my instructions'),
    ('~08:00', 'Sent to Qwen for independent review - 7 MORE issues surfaced'),
    ('~09:00', 'Digital twin landscape report drafted'),
    ('~10:00', 'JBS formatting, self-verify, corrections'),
    ('~14:00', 'Voice note while kitchen pacing - small strata investigation'),
    ('~15:00', 'Workflow codified into reusable skill file'),
]
for time, event in timeline:
    pdf.set_font('DJ', 'B', 8); pdf.set_text_color(46,134,171)
    pdf.set_xy(18, y); pdf.cell(22, 5, time)
    pdf.set_font('DJ', '', 8); pdf.set_text_color(60,60,60)
    pdf.cell(200, 5, event)
    y += 5.5

# === Slide 5: Deliverables ===
y = pdf.slide_start('What Came Out of It')
y = pdf.bullet('Deliverables in ~8 hours of active collaboration:', bold=True, y=y)
y = pdf.bullet('12-page Ridge-Cal manuscript - submission-ready for JBS', y=y)
y = pdf.bullet('Response to Reviewer 2 - point-by-point rebuttal', y=y)
y = pdf.bullet('Digital twin landscape survey (12 pages, 3 diagrams) - for BLT', y=y)
y = pdf.bullet('Small strata white paper with SAP language recommendations', y=y)
y = pdf.bullet('Research Workflow skill file (SKILL.md) - reusable', y=y)
y = pdf.bullet('All simulation code on GitHub (public repos)', y=y)

# === Slide 6: Multi-Model Review ===
pdf.section_slide('The Multi-Model Review Loop')
y = pdf.slide_start('Why Not One AI?')
y = pdf.bullet('Same-model reviewers share the same blind spots and hallucination patterns', y=y)
y = y + 3
y = pdf.bullet('Internal Loop (my OpenClaw agent, ~$0.15/M tokens):', bold=True, y=y)
y = pdf.bullet('Primary work: DeepSeek v4 Flash | Independent reviewer: Qwen', y=y)
y = pdf.bullet('Caught: Section 4 redundancy, delta justification, missing data, table headers', y=y)
y = y + 3
y = pdf.bullet('External Loop (separate AI, separate company):', bold=True, y=y)
y = pdf.bullet('Gemini Pro - completely different training, different blind spots', y=y)
y = pdf.bullet('Caught: Non-collapsibility, tone, event rates, LoRA framing', y=y)

# === Slide 7: Convergence ===
y = pdf.slide_start('The Convergence', color=(25,26,46))
pdf.set_text_color(220,220,230)
y = pdf.bullet('Gemini: Major Revision -> Accept (1 round, 4 issues)', y=y)
y = pdf.bullet('Qwen: Major -> Minor -> Accept (3 rounds, 7 DIFFERENT issues)', y=y)
y = pdf.bullet('Total: 11 distinct bugs caught by 2 different AI models', y=y)
y = y + 5
y = pdf.bullet('Qwen caught things Gemini completely missed:', bold=True, y=y)
y = pdf.bullet('Section 4 redundancy, delta = 0.01 justification, table header ambiguity', y=y)
y = pdf.bullet('MAP-Cox unfair framing, sandwich variance scope', y=y)
y = pdf.bullet('Missing data acknowledgment, reference formatting', y=y)
y = pdf.bullet('Takeaway: model-diverse review converges faster than any single reviewer', y=y)

# === Slide 8: Demo ===
pdf.section_slide('Demo: Voice Note to White Paper in 10 Minutes')
y = pdf.slide_start('The Small Strata Investigation')
y = pdf.bullet('Input: Me pacing the kitchen, talking to my phone:', bold=True, y=y)
y = pdf.bullet('"Do we need to pool small strata for CMH and MN methods?"', y=y)
y = pdf.bullet('Whisper transcribed it on-device in < 1 min', y=y)
y = y + 3
steps = [
    ('1m', 'Problem scoping - I dictated, agent structured into Phase 0 proposal'),
    ('1m', 'Independent Qwen review (isolated) - caught framing weakness'),
    ('1m', 'I directed reframing as internal white paper'),
    ('3m', 'Agent drafted R code, I reviewed specs, agent ran 5K reps'),
    ('1m', 'Code review v1 - Qwen caught 3 bugs in our simulation'),
    ('1m', 'Code review v2 - agent verified fixes, I confirmed'),
    ('1m', 'Final review - white paper compiled, ready'),
    ('<1m', 'Pushed to public GitHub repo'),
]
for step, desc in steps:
    pdf.set_font('DJ', 'B', 8); pdf.set_text_color(46,134,171)
    pdf.set_xy(18, y); pdf.cell(16, 5, step)
    pdf.set_font('DJ', '', 8); pdf.set_text_color(60,60,60)
    pdf.cell(200, 5, desc)
    y += 5.5

# === Slide 9: Results Table ===
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
    'Conclusion: No pooling required for any method.\n'
    'Code reviews caught: Scenario 4 duplicated, RR variance unstratified, Wald mislabeled as MN.\n'
    'All bugs fixed before delivery - independent AI review caught what we overlooked.')

# === Slide 10: Workflow ===
pdf.section_slide('The Research Workflow That Emerged')
y = pdf.slide_start('Codified into a Reusable Skill File - 8 Phases')
phases = [
    ('Ph 0: Topic ID', 'Identify gap, map contradictory literature'),
    ('Ph 1: Writeup', 'Write, spawn isolated reviewer, iterate'),
    ('Ph 2: Simulate', '2 -> 20 -> 200 -> 10,000 reps (progressive)'),
    ('Ph 3: QC', 'CODE REVIEW BEFORE BIG RUNS - mandatory checkpoint'),
    ('Ph 4: Full Run', 'Background, scheduled, monitored'),
    ('Ph 4.5: Audit', 'Verify code matches manuscript claims'),
    ('Ph 5: Manuscript', 'Write, verify refs, PDF self-check, senior review'),
    ('Ph 6: Revision', 'Parse -> Reconcile -> Re-sim -> Diff check'),
    ('Ph 7: Submit', 'Independent reviewer -> Revise -> Max 3 rounds'),
]
for phase, desc in phases:
    pdf.set_font('DJ', 'B', 8); pdf.set_text_color(46,134,171)
    pdf.set_xy(18, y); pdf.cell(28, 5, phase)
    pdf.set_font('DJ', '', 8); pdf.set_text_color(60,60,60)
    pdf.cell(190, 5, desc)
    y += 5.5

# === Slide 11: Key Rules ===
y = pdf.slide_start('Key Lessons Codified')
y = pdf.bullet('1. Isolate reviewers - fresh sessions, no cross-contamination', y=y)
y = pdf.bullet('2. Diversify models - different AIs catch different bugs', y=y)
y = pdf.bullet('3. Code review BEFORE big simulations - trust but verify', y=y)
y = pdf.bullet('4. PDF self-verify - programmatic checks before sending to humans', y=y)
y = pdf.bullet('5. Clean up cruft every iteration - stale files cause confusion', y=y)
y = pdf.bullet('6. Push to GitHub at milestones - enables external review', y=y)
y = pdf.bullet('7. Batch deliveries - dont send incremental fixes, pace yourself', y=y)

# === Slide 12: Takeaways ===
y = pdf.slide_start('Key Takeaways')
y = pdf.bullet('What Worked Well:', bold=True, y=y)
y = pdf.bullet('Independent AI reviewers caught 11 bugs before human eyes saw the draft', y=y)
y = pdf.bullet('Small tests before big runs - avoided ~5 dead ends', y=y)
y = pdf.bullet('Human-in-the-loop essential - I directed 8 reframing cycles', y=y)
y = pdf.bullet('The agent amplified judgment, did not replace it', y=y)
y = y + 4
y = pdf.bullet('What We Would Do Differently:', bold=True, y=y)
y = pdf.bullet('PDF generation was painful - 5 failed attempts, silent image failures', y=y)
y = pdf.bullet('Now has a verification script baked into the pipeline', y=y)
y = pdf.bullet('Code review almost skipped - hard checkpoint now', y=y)
y = pdf.bullet('Stale artifacts accumulated - explicit cleanup at milestones', y=y)

# === Slide 13: Economics ===
y = pdf.slide_start('The Bottom Line')
y = pdf.bullet('Session cost: ~500K DeepSeek tokens, well under $1.00', y=y)
y = pdf.bullet('That bought:', bold=True, y=y)
y = pdf.bullet('1 manuscript ready for JBS submission', y=y)
y = pdf.bullet('1 report for BLT - digital twin landscape (12 pages, 3 diagrams)', y=y)
y = pdf.bullet('1 complete simulation study + white paper + SAP language', y=y)
y = pdf.bullet('1 reusable research workflow skill', y=y)
y = pdf.bullet('3 independent AI reviews from 2 different model architectures', y=y)
y = pdf.bullet('3 GitHub repos with full code', y=y)
y = y + 4
y = pdf.bullet('Key insight:', bold=True, y=y)
y = pdf.bullet('The agent doesnt replace the statistician - it replaces the drafting lag and review cycle', y=y)
y = pdf.bullet('What used to take a week of calendar coordination now takes an evening', y=y)

# === Slide 14: Thank You ===
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
    'The skill: SKILL.md in my OpenClaw workspace - available on request', align='C')

pdf.output('/home/yue-shentu/.openclaw/workspace/research-proposals/talk-slides.pdf')
sz = os.path.getsize('/home/yue-shentu/.openclaw/workspace/research-proposals/talk-slides.pdf')
print(f'OK: talk-slides.pdf ({sz/1024:.0f} KB, {pdf.page_no()} slides)')
