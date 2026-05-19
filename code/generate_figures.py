#!/usr/bin/env python3
"""Generate professional diagrams for the digital twin landscape report."""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import numpy as np
import os

outdir = '/home/yue-shentu/.openclaw/workspace/research-proposals/figures'
os.makedirs(outdir, exist_ok=True)

# Style
plt.rcParams.update({
    'font.family': 'DejaVu Sans',
    'font.size': 10,
    'axes.facecolor': '#f8f9fa',
    'figure.facecolor': 'white',
})

# ============================================================
# Diagram 1: Vendor Ecosystem Market Structure
# ============================================================
def draw_vendor_ecosystem():
    fig, ax = plt.subplots(1, 1, figsize=(10, 6.5))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 7)
    ax.axis('off')
    
    # Colors
    c_dtaas = '#2E86AB'
    c_platform = '#A23B72'
    c_cro = '#F18F01'
    c_academic = '#6B8F71'
    c_center = '#1A1A2E'
    
    # Title
    ax.text(5, 6.6, 'Digital Twin Ecosystem in Clinical Development', 
            ha='center', va='center', fontsize=14, fontweight='bold', color=c_center)
    
    # Center box: "DTaaS"
    center = FancyBboxPatch((3.2, 4.8), 3.6, 0.7, 
                            boxstyle="round,pad=0.15", 
                            facecolor=c_dtaas, edgecolor='white', linewidth=2)
    ax.add_patch(center)
    ax.text(5, 5.15, 'DTaaS (Digital Twin as a Service)', ha='center', va='center',
            fontsize=11, fontweight='bold', color='white')
    ax.text(5, 4.85, 'Unlearn.AI, Altis Labs, Phesi, InSilico Medicine', 
            ha='center', va='center', fontsize=8, color='white', alpha=0.9)
    ax.text(5, 4.55, 'Revenue: $500K–$2M per trial', ha='center', va='center',
            fontsize=7, color=c_dtaas, style='italic')
    
    # Left box: MIDD Software
    left = FancyBboxPatch((0.3, 3.0), 2.8, 0.9,
                          boxstyle="round,pad=0.12",
                          facecolor=c_platform, edgecolor='white', linewidth=2)
    ax.add_patch(left)
    ax.text(1.7, 3.55, 'MIDD Software Platforms', ha='center', va='center',
            fontsize=10, fontweight='bold', color='white')
    ax.text(1.7, 3.25, 'Certara, Simulations Plus\nPumas-AI, Rosa & Co', 
            ha='center', va='center', fontsize=8, color='white', alpha=0.9)
    
    # Right box: CRO Services
    right = FancyBboxPatch((6.9, 3.0), 2.8, 0.9,
                           boxstyle="round,pad=0.12",
                           facecolor=c_cro, edgecolor='white', linewidth=2)
    ax.add_patch(right)
    ax.text(8.3, 3.55, 'CRO Services', ha='center', va='center',
            fontsize=10, fontweight='bold', color='white')
    ax.text(8.3, 3.25, 'IQVIA MIDD, Parexel/QS\nLabcorp, PPD/ThermoFisher', 
            ha='center', va='center', fontsize=8, color='white', alpha=0.9)
    
    # Bottom box: Academic / Open Source
    bottom = FancyBboxPatch((3.2, 1.0), 3.6, 1.0,
                            boxstyle="round,pad=0.12",
                            facecolor=c_academic, edgecolor='white', linewidth=2)
    ax.add_patch(bottom)
    ax.text(5, 1.55, 'Academic & Open Source Groups', ha='center', va='center',
            fontsize=10, fontweight='bold', color='white')
    ax.text(5, 1.25, 'Imperial College, JHU\nSeattle Children\'s, NIH Consortia', 
            ha='center', va='center', fontsize=8, color='white', alpha=0.9)
    
    # Arrows from center to left/right/bottom
    arrow_style = dict(arrowstyle='->', lw=2, color='#666666')
    ax.annotate('', xy=(1.7, 3.9), xytext=(4.0, 4.8),
                arrowprops=dict(arrowstyle='->', lw=2, color='#999', connectionstyle='arc3,rad=-0.15'))
    ax.annotate('', xy=(8.3, 3.9), xytext=(6.0, 4.8),
                arrowprops=dict(arrowstyle='->', lw=2, color='#999', connectionstyle='arc3,rad=0.15'))
    ax.annotate('', xy=(5.0, 2.0), xytext=(5.0, 4.8),
                arrowprops=dict(arrowstyle='->', lw=2, color='#999'))
    
    # Revenue labels on arrows
    ax.text(2.7, 4.4, 'Licenses\n$500K/yr', ha='center', va='center',
            fontsize=7, color='#666', fontweight='bold')
    ax.text(7.3, 4.4, 'Consulting\n$500–2K/hr', ha='center', va='center',
            fontsize=7, color='#666', fontweight='bold')
    ax.text(5.5, 3.4, 'Grants\n(free software)', ha='center', va='center',
            fontsize=7, color='#666', fontweight='bold')
    
    # Legend / Key players at the bottom
    legend_y = 0.3
    categories = [
        ('DTaaS', c_dtaas, 'Unlearn, Altis, Phesi'),
        ('Platform', c_platform, 'Certara, Pumas-AI'),
        ('CRO', c_cro, 'IQVIA, Parexel'),
        ('Academic', c_academic, 'JHU, Imperial'),
    ]
    for i, (name, color, players) in enumerate(categories):
        x = 1.5 + i * 2.2
        patch = mpatches.Circle((x, legend_y), 0.12, color=color, ec='white', lw=1)
        ax.add_patch(patch)
        ax.text(x + 0.2, legend_y, f'{name}: {players}', va='center', fontsize=7, color='#555')
    
    plt.tight_layout()
    fig.savefig(f'{outdir}/vendor-ecosystem.pdf', bbox_inches='tight', dpi=200)
    fig.savefig(f'{outdir}/vendor-ecosystem.png', bbox_inches='tight', dpi=200)
    plt.close()
    print('✅ Vendor ecosystem diagram saved')


# ============================================================
# Diagram 2: Methodological Taxonomy Tree
# ============================================================
def draw_taxonomy():
    fig, ax = plt.subplots(1, 1, figsize=(10, 7))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 8)
    ax.axis('off')
    
    # Colors
    c_root = '#1A1A2E'
    c_stat = '#2E86AB'
    c_mech = '#A23B72'
    c_hybrid = '#6B8F71'
    c_method = '#4A4A4A'
    c_highlight = '#E9A820'
    
    # Root
    root = FancyBboxPatch((3.0, 7.2), 4.0, 0.55, 
                          boxstyle="round,pad=0.15",
                          facecolor=c_root, edgecolor='white', linewidth=2)
    ax.add_patch(root)
    ax.text(5, 7.48, 'Prognostic Score / Synthetic Control Methods', 
            ha='center', va='center', fontsize=10, fontweight='bold', color='white')
    
    # Branch: Statistical Approaches
    stat_box = FancyBboxPatch((0.2, 5.3), 3.6, 0.5,
                              boxstyle="round,pad=0.1",
                              facecolor=c_stat, edgecolor='white', linewidth=2)
    ax.add_patch(stat_box)
    ax.text(2.0, 5.55, 'Statistical Approaches', ha='center', va='center',
            fontsize=9, fontweight='bold', color='white')
    ax.annotate('', xy=(2.0, 5.3), xytext=(5.0, 7.2),
                arrowprops=dict(arrowstyle='->', lw=2, color=c_stat, connectionstyle='arc3,rad=-0.2'))
    
    # Statistical sub-methods
    stat_methods = [
        (0.2, 3.8, 'PROCOVA (Schuler 2021)', 'Prognostic score as covariate\nEMA qualified for Ph2/3'),
        (0.2, 2.5, 'Bayesian Borrowing', 'Power / Commensurate / MAP priors\nSchmidli 2014, Hobbs 2011'),
        (0.2, 1.2, 'Synthetic Control Arms', 'Matching/weighting external data\nFDA guidance (2023 draft)'),
    ]
    for x, y, title, desc in stat_methods:
        box = FancyBboxPatch((x, y), 3.6, 0.9,
                             boxstyle="round,pad=0.08",
                             facecolor='white', edgecolor=c_stat, linewidth=1.5)
        ax.add_patch(box)
        ax.text(x + 0.2, y + 0.65, title, fontsize=8, fontweight='bold', color=c_stat)
        ax.text(x + 0.2, y + 0.3, desc, fontsize=7, color='#555', va='top')
        # Small connecting line
        ax.plot([x + 0.5, x + 0.5], [y + 0.9, 5.3], lw=1, color=c_stat, alpha=0.4)
    
    # Highlight: Calibration methods box
    cal_box = FancyBboxPatch((0.5, 3.9), 3.0, 0.7,
                             boxstyle="round,pad=0.08",
                             facecolor=c_highlight, edgecolor='#C88A00', linewidth=2, alpha=0.15)
    ax.add_patch(cal_box)
    ax.text(2.0, 4.3, '← Calibration methods (internal research)', 
            fontsize=7, color='#C88A00', fontweight='bold', ha='center')
    
    # Branch: Mechanistic Approaches
    mech_box = FancyBboxPatch((6.2, 5.3), 3.6, 0.5,
                              boxstyle="round,pad=0.1",
                              facecolor=c_mech, edgecolor='white', linewidth=2)
    ax.add_patch(mech_box)
    ax.text(8.0, 5.55, 'Mechanistic Approaches', ha='center', va='center',
            fontsize=9, fontweight='bold', color='white')
    ax.annotate('', xy=(8.0, 5.3), xytext=(5.0, 7.2),
                arrowprops=dict(arrowstyle='->', lw=2, color=c_mech, connectionstyle='arc3,rad=0.2'))
    
    mech_methods = [
        (6.2, 3.8, 'ODE-based Physiology', 'Virtual heart (JHU FDA pilot)\nAntibody kinetics (vaccines)'),
        (6.2, 2.5, 'PK/PD Models', 'Standard pharmacometric\nmodeling workflow'),
        (6.2, 1.2, 'Agent-based Models', 'Tumor growth / immune\nresponse simulation'),
    ]
    for x, y, title, desc in mech_methods:
        box = FancyBboxPatch((x, y), 3.6, 0.9,
                             boxstyle="round,pad=0.08",
                             facecolor='white', edgecolor=c_mech, linewidth=1.5)
        ax.add_patch(box)
        ax.text(x + 0.2, y + 0.65, title, fontsize=8, fontweight='bold', color=c_mech)
        ax.text(x + 0.2, y + 0.3, desc, fontsize=7, color='#555', va='top')
        ax.plot([x + 0.5, x + 0.5], [y + 0.9, 5.3], lw=1, color=c_mech, alpha=0.4)
    
    # Branch: Hybrid
    hybrid_box = FancyBboxPatch((3.0, 4.2), 4.0, 0.5,
                                boxstyle="round,pad=0.1",
                                facecolor=c_hybrid, edgecolor='white', linewidth=2)
    ax.add_patch(hybrid_box)
    ax.text(5.0, 4.45, 'Hybrid: Mechanistic + AI', ha='center', va='center',
            fontsize=9, fontweight='bold', color='white')
    ax.annotate('', xy=(5.0, 4.2), xytext=(5.0, 7.2),
                arrowprops=dict(arrowstyle='->', lw=2, color=c_hybrid))
    
    # Bottom note
    ax.text(5, 0.3, 'Source: Literature review (May 2026). Blue highlight indicates areas of active internal research.',
            ha='center', va='center', fontsize=7, color='#999', style='italic')
    
    plt.tight_layout()
    fig.savefig(f'{outdir}/method-taxonomy.pdf', bbox_inches='tight', dpi=200)
    fig.savefig(f'{outdir}/method-taxonomy.png', bbox_inches='tight', dpi=200)
    plt.close()
    print('✅ Taxonomy diagram saved')


# ============================================================
# Diagram 3: Hype vs Reality comparison chart
# ============================================================
def draw_hype_reality():
    fig, ax = plt.subplots(1, 1, figsize=(10, 4.5))
    
    claims = [
        'Replace control arms',
        'Reduce N by 50%',
        'Individual predictions',
        'Full physiological twin',
        'Works for any indication',
    ]
    
    reality = [0.15, 0.25, 0.10, 0.05, 0.30]
    hype = [0.85, 0.70, 0.80, 0.75, 0.60]
    
    y_pos = np.arange(len(claims))
    height = 0.35
    
    ax.barh(y_pos + height/2, hype, height, label='Hype', color='#E9A820', alpha=0.7)
    ax.barh(y_pos - height/2, reality, height, label='Reality (evidence level)', color='#2E86AB', alpha=0.8)
    
    ax.set_yticks(y_pos)
    ax.set_yticklabels(claims, fontsize=10)
    ax.set_xlabel('Proportion of claims that are hype vs evidence-supported', fontsize=9)
    ax.set_xlim(0, 1)
    ax.legend(loc='lower right', fontsize=9)
    ax.grid(axis='x', alpha=0.3)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    
    plt.tight_layout()
    fig.savefig(f'{outdir}/hype-reality.pdf', bbox_inches='tight', dpi=200)
    fig.savefig(f'{outdir}/hype-reality.png', bbox_inches='tight', dpi=200)
    plt.close()
    print('✅ Hype vs reality chart saved')


if __name__ == '__main__':
    draw_vendor_ecosystem()
    draw_taxonomy()
    draw_hype_reality()
    print(f'\nAll diagrams saved to {outdir}/')
