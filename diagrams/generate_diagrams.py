import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Ensure diagrams directory exists
diagrams_dir = os.path.dirname(os.path.abspath(__file__))
os.makedirs(diagrams_dir, exist_ok=True)

# Helper function to save figures in high resolution
def save_fig(fig, filename):
    path = os.path.join(diagrams_dir, filename)
    fig.savefig(path, bbox_inches='tight', dpi=150)
    plt.close(fig)
    print(f"Saved {filename}")

# Define color palettes
PALETTES = {
    "simple": {
        "bg": "#FFFFFF",
        "box_bg": "#FFFFFF",
        "box_edge": "#000000",
        "text": "#000000",
        "arrow": "#000000",
        "line": "#000000"
    },
    "polished": {
        "bg": "#F8FAFF",
        "box_bg": "#FFFFFF",
        "box_edge": "#1A237E",  # Indigo border
        "text": "#1A237E",
        "arrow": "#3F51B5",
        "line": "#5C6BC0"
    }
}

# ==========================================
# 1. PROCESS FLOW DIAGRAM (ZIG-ZAG FLOWCHART)
# ==========================================
def draw_flow_diagram(style):
    p = PALETTES[style]
    fig, ax = plt.subplots(figsize=(13, 9), facecolor=p["bg"])
    ax.set_facecolor(p["bg"])
    ax.set_xlim(0, 13)
    ax.set_ylim(0, 10)
    ax.axis('off')

    title = "System Process Flow Diagram"
    if style == "simple":
        ax.text(6.5, 9.6, title, fontsize=15, fontweight='bold', ha='center', color=p["text"])
    else:
        ax.text(6.5, 9.6, title, fontsize=16, fontweight='bold', ha='center', color=p["box_edge"])

    # Define boxes and coordinates
    # Row 1 (Left to Right)
    # Row 2 (Right to Left)
    # Row 3 (Left to Right)
    boxes = [
        # Row 1: Left to Right
        (1.8, 8.0, "Student Mobile Application\n(Text / Voice / Camera Input)"),
        (4.9, 8.0, "Checks Local Server\nPort 8000"),
        (8.0, 8.0, "FastAPI Backend (/ask API)\nReceives Query via HTTP POST"),
        (11.1, 8.0, "Language Detection &\nHybrid Translation\n(Google / Argos Fallback)"),

        # Row 2: Right to Left
        (11.1, 5.0, "Query Vectorization\n(Sentence Embedding Model)"),
        (8.0, 5.0, "FAISS Vector Database\nL2 Similarity Search\nRetrieve Top-K Passages"),
        (4.9, 5.0, "Prompt Assembly\nQuery + Retrieved Context"),
        (1.8, 5.0, "TinyLlama LLM\nResponse Generation"),

        # Row 3: Left to Right
        (1.8, 2.0, "Translate Response to\nUser Preferred Language\n(Google / Argos Fallback)"),
        (4.9, 2.0, "Text Display + TTS Audio\nResponse Rendering"),
        (8.0, 2.0, "XP & Streak Counter Update\n(Gamification Module)")
    ]

    box_width = 2.5
    box_height = 1.3

    for idx, (x, y, text) in enumerate(boxes):
        # Draw rounded rectangle box
        rect = patches.FancyBboxPatch(
            (x - box_width/2, y - box_height/2), box_width, box_height,
            boxstyle="round,pad=0.1",
            linewidth=1.8,
            edgecolor=p["box_edge"],
            facecolor=p["box_bg"],
            mutation_aspect=1.0
        )
        ax.add_patch(rect)
        ax.text(x, y, text, fontsize=8.5, ha='center', va='center', color=p["text"], fontweight='normal')

    # Draw connection arrows
    arrow_props = dict(arrowstyle="-|>", color=p["arrow"], lw=2.0, mutation_scale=15)

    # Row 1 Horizontal Arrows
    ax.annotate("", xy=(4.9 - 1.25, 8.0), xytext=(1.8 + 1.25, 8.0), arrowprops=arrow_props)
    ax.annotate("", xy=(8.0 - 1.25, 8.0), xytext=(4.9 + 1.25, 8.0), arrowprops=arrow_props)
    ax.annotate("", xy=(11.1 - 1.25, 8.0), xytext=(8.0 + 1.25, 8.0), arrowprops=arrow_props)

    # Row 1 to Row 2 Vertical Down Arrow
    ax.annotate("", xy=(11.1, 5.0 + 0.65), xytext=(11.1, 8.0 - 0.65), arrowprops=arrow_props)

    # Row 2 Horizontal Arrows (Right to Left)
    ax.annotate("", xy=(8.0 + 1.25, 5.0), xytext=(11.1 - 1.25, 5.0), arrowprops=arrow_props)
    ax.annotate("", xy=(4.9 + 1.25, 5.0), xytext=(8.0 - 1.25, 5.0), arrowprops=arrow_props)
    ax.annotate("", xy=(1.8 + 1.25, 5.0), xytext=(4.9 - 1.25, 5.0), arrowprops=arrow_props)

    # Row 2 to Row 3 Vertical Down Arrow
    ax.annotate("", xy=(1.8, 2.0 + 0.65), xytext=(1.8, 5.0 - 0.65), arrowprops=arrow_props)

    # Row 3 Horizontal Arrows
    ax.annotate("", xy=(4.9 - 1.25, 2.0), xytext=(1.8 + 1.25, 2.0), arrowprops=arrow_props)
    ax.annotate("", xy=(8.0 - 1.25, 2.0), xytext=(4.9 + 1.25, 2.0), arrowprops=arrow_props)

    save_fig(fig, "flow_diagram.png")

# ==========================================
# 2. FLUTTER CLIENT ARCHITECTURE (4 LAYERS STACK)
# ==========================================
def draw_block_diagram(style):
    p = PALETTES[style]
    fig, ax = plt.subplots(figsize=(10, 9), facecolor=p["bg"])
    ax.set_facecolor(p["bg"])
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 10)
    ax.axis('off')

    title = "Flutter Client Architecture"
    if style == "simple":
        ax.text(5.0, 9.5, title, fontsize=15, fontweight='bold', ha='center', color=p["text"])
    else:
        ax.text(5.0, 9.5, title, fontsize=16, fontweight='bold', ha='center', color=p["box_edge"])

    layers = [
        ("User Interface Layer:",
         "Consists of three main screens: Dashboard (Tutor Chat), Quiz, and Profile.\nAll screens share a unified Material Design 3 styling with Inter typography.", 7.8),
        ("Network and Discovery Layer:",
         "A background Heartbeat Prober timer continuously scans the local subnet\n(probes gateway and .2 through .15 range on port 8000) every 15s to locate the server IP address automatically.", 5.6),
        ("Hardware API Layer:",
         "Interfaces with the smartphone microphone (STT), speaker (TTS),\nand camera (Image Picker & Google ML Kit OCR) for multimodal input and output.", 3.4),
        ("Local Storage Layer:",
         "Uses Shared Preferences for lightweight key-value persistence of student profiles,\nXP scores, streak data, server URL caching, and offline textbook chapters.", 1.2)
    ]

    box_w = 8.5
    box_h = 1.6

    for idx, (layer_title, layer_desc, y) in enumerate(layers):
        # Draw box
        rect = patches.FancyBboxPatch(
            (5.0 - box_w/2, y - box_h/2), box_w, box_h,
            boxstyle="round,pad=0.1",
            linewidth=1.8,
            edgecolor=p["box_edge"],
            facecolor=p["box_bg"],
            mutation_aspect=1.0
        )
        ax.add_patch(rect)

        # Add Text
        ax.text(5.0, y + 0.4, layer_title, fontsize=10, fontweight='bold', ha='center', color=p["text"])
        ax.text(5.0, y - 0.25, layer_desc, fontsize=8.5, ha='center', va='center', color=p["text"])

        # Arrow down
        if idx < len(layers) - 1:
            ax.annotate("", xy=(5.0, y - 0.8 - 0.1), xytext=(5.0, y - 0.8 + 0.2),
                        arrowprops=dict(arrowstyle="-|>", color=p["arrow"], lw=2.0, mutation_scale=15))

    save_fig(fig, "block_diagram.png")

# ==========================================
# 3. RAG PIPELINE WORKFLOW (6 LAYERS STACK)
# ==========================================
def draw_rag_workflow(style):
    p = PALETTES[style]
    fig, ax = plt.subplots(figsize=(10, 11), facecolor=p["bg"])
    ax.set_facecolor(p["bg"])
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 12)
    ax.axis('off')

    title = "RAG Pipeline Workflow"
    if style == "simple":
        ax.text(5.0, 11.5, title, fontsize=15, fontweight='bold', ha='center', color=p["text"])
    else:
        ax.text(5.0, 11.5, title, fontsize=16, fontweight='bold', ha='center', color=p["box_edge"])

    steps = [
        ("NCERT Data Collection:", "Raw NCERT textbook PDFs are cleaned, formatted, and\norganized into structured Markdown files during the setup phase."),
        ("Data Chunking:", "Large textbook chapters are segmented into smaller 300-word\npassages to improve retrieval precision and reduce context window overhead."),
        ("Embedding Generation:", "Each text passage is encoded into a 768-dimensional\nnumerical vector using the Sentence Transformer model, capturing semantic meaning."),
        ("Vector Database Storage:", "All passage embeddings are indexed and stored in a\nFAISS flat L2 index for efficient similarity search."),
        ("Query Retrieval:", "The incoming student query is vectorized and compared against stored\npassage embeddings using L2 Euclidean distance to retrieve the top-k most relevant passages."),
        ("LLM Response Generation:", "The retrieved passages are assembled into a context-grounded prompt and\npassed to TinyLlama, which generates a student-friendly educational explanation.")
    ]

    y_start = 10.2
    y_step = 1.7
    box_w = 8.5
    box_h = 1.3

    for idx, (step_title, step_desc) in enumerate(steps):
        y = y_start - idx * y_step
        # Draw box
        rect = patches.FancyBboxPatch(
            (5.0 - box_w/2, y - box_h/2), box_w, box_h,
            boxstyle="round,pad=0.1",
            linewidth=1.8,
            edgecolor=p["box_edge"],
            facecolor=p["box_bg"],
            mutation_aspect=1.0
        )
        ax.add_patch(rect)

        # Add Text
        ax.text(5.0, y + 0.3, step_title, fontsize=10, fontweight='bold', ha='center', color=p["text"])
        ax.text(5.0, y - 0.22, step_desc, fontsize=8.5, ha='center', va='center', color=p["text"])

        # Arrow down
        if idx < len(steps) - 1:
            ax.annotate("", xy=(5.0, y - box_h/2 - 0.3), xytext=(5.0, y - box_h/2 + 0.1),
                        arrowprops=dict(arrowstyle="-|>", color=p["arrow"], lw=2.0, mutation_scale=15))

    # Saved with expected file name format to replace the old ones
    # Note: RAG Pipeline workflow is actually replacement for RAG workflow
    # Let's save it directly as block_diagram_simple.png or custom name, wait, let's keep it named as use_case_diagram etc.?
    # Wait, the list of diagrams in diagrams/ folder is:
    # flow_diagram, block_diagram (Client Architecture), use_case_diagram, sequence_diagram.
    # What about RAG pipeline? Let's save it as RAG_workflow.png and RAG_workflow_simple.png!
    # That way it exists for report.
    save_fig(fig, "RAG_workflow.png")

# ==========================================
# 4. UML SEQUENCE DIAGRAM
# ==========================================
def draw_sequence_diagram(style):
    p = PALETTES[style]
    fig, ax = plt.subplots(figsize=(15, 11), facecolor=p["bg"])
    ax.set_facecolor(p["bg"])
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 15)
    ax.axis('off')

    title = "Sequence Diagram of GramNet AI System"
    if style == "simple":
        ax.text(8.0, 14.4, title, fontsize=15, fontweight='bold', ha='center', color=p["text"])
    else:
        ax.text(8.0, 14.4, title, fontsize=16, fontweight='bold', ha='center', color=p["box_edge"])

    # Define coordinates dictionary to allow automatic scaling and prevent overlaps
    coord = {
        "Student": 1.0,
        "UI": 2.4,
        "STT": 3.8,
        "OCR": 5.2,
        "NLP": 6.9,
        "RAG": 8.6,
        "DB": 10.3,
        "LLM": 11.9,
        "TTS": 13.4,
        "Out": 14.9
    }

    # Define participants
    participants = [
        ("Student", coord["Student"], "actor"),
        ("Input\nInterface\n(Text/Voice)", coord["UI"], "box"),
        ("Speech-to-Text\n(STT) Module", coord["STT"], "box"),
        ("Camera & OCR\nModule", coord["OCR"], "box"),
        ("NLP Processing\n(Lang Detect,\nTranslation, Cleaning)", coord["NLP"], "box"),
        ("RAG Retrieval\nModule", coord["RAG"], "box"),
        ("Vector Database\n(NCERT Content)", coord["DB"], "box"),
        ("TinyLlama GGUF\n(LLM)", coord["LLM"], "box"),
        ("Text-to-Speech\n(TTS) Module", coord["TTS"], "box"),
        ("Output\nInterface\n(Text/Voice)", coord["Out"], "box")
    ]

    # Draw participant boxes/actors and dashed lifelines
    for name, x, p_type in participants:
        if p_type == "actor":
            # Draw stick figure head
            circle = patches.Circle((x, 13.5), 0.15, linewidth=1.5, edgecolor=p["box_edge"], facecolor=p["bg"])
            ax.add_patch(circle)
            # Body
            ax.plot([x, x], [13.35, 12.9], color=p["box_edge"], lw=1.5)
            # Arms
            ax.plot([x - 0.2, x + 0.2], [13.2, 13.2], color=p["box_edge"], lw=1.5)
            # Legs
            ax.plot([x, x - 0.15], [12.9, 12.4], color=p["box_edge"], lw=1.5)
            ax.plot([x, x + 0.15], [12.9, 12.4], color=p["box_edge"], lw=1.5)
            ax.text(x, 12.1, name, fontsize=8.5, fontweight='bold', ha='center', color=p["text"])
        else:
            # Draw box
            rect = patches.Rectangle((x - 0.6, 12.7), 1.2, 0.95, linewidth=1.5,
                                     edgecolor=p["box_edge"], facecolor=p["box_bg"])
            ax.add_patch(rect)
            ax.text(x, 13.15, name, fontsize=7, fontweight='bold', ha='center', va='center', color=p["text"])

        # Lifeline
        ax.plot([x, x], [0.8, 12.3 if p_type == "actor" else 12.6], color="#757575", linestyle="--", linewidth=1.0)

    # Sequence steps (y_pos, from_x, to_x, label, arrowstyle, label_offset_y)
    steps = [
        (11.6, coord["Student"], coord["UI"], "1. Submit Query\n(Text, Voice, Image)", "->", 0.15),
        (11.0, coord["UI"], coord["STT"], "2. If Voice Input", "->", 0.15),
        (10.5, coord["STT"], coord["UI"], "3. Converted Text", "-->", 0.15),
        (10.0, coord["UI"], coord["OCR"], "2b. If Image / Camera Input", "->", 0.15),
        (9.5, coord["OCR"], coord["UI"], "3b. Recognized Text", "-->", 0.15),
        (8.9, coord["UI"], coord["NLP"], "4. Send Text for Processing", "->", 0.15),
        (8.3, coord["NLP"], coord["NLP"], "5. Language Detection,\nTranslation, Text Cleaning", "loop", 0.25),
        (7.4, coord["NLP"], coord["RAG"], "6. Processed Query", "->", 0.15),
        (6.9, coord["RAG"], coord["DB"], "7. Search Relevant Information", "->", 0.15),
        (6.4, coord["DB"], coord["RAG"], "8. Retrieved Context", "-->", 0.15),
        (5.9, coord["RAG"], coord["LLM"], "9. Send Query + Context", "->", 0.15),
        (5.3, coord["LLM"], coord["LLM"], "10. Generate Response", "loop", 0.25),
        (4.4, coord["LLM"], coord["RAG"], "11. Generated Response", "-->", 0.15),
        (3.9, coord["RAG"], coord["NLP"], "12. Final Response\n(Text in English)", "-->", 0.15),
        (3.3, coord["NLP"], coord["NLP"], "13. Translate to User's\nPreferred Language", "loop", 0.25),
        (2.4, coord["NLP"], coord["UI"], "14. Final Response (Text)", "-->", 0.15),
        (1.9, coord["UI"], coord["TTS"], "15. If Voice Output Enabled", "->", 0.15),
        (1.4, coord["TTS"], coord["UI"], "16. Audio Output (Speech)", "-->", 0.15),
        (0.9, coord["UI"], coord["Out"], "17. Display Response to User (Text/Voice)", "->", 0.15)
    ]

    # Draw sequence activation bars (small grey boxes where lifelines are active)
    active_lifelines = [
        (coord["Student"], 0.8, 11.8),
        (coord["UI"], 0.8, 11.7),
        (coord["STT"], 10.4, 11.1),
        (coord["OCR"], 9.4, 10.1),
        (coord["NLP"], 2.3, 9.0),
        (coord["RAG"], 3.8, 7.5),
        (coord["DB"], 6.3, 7.0),
        (coord["LLM"], 4.3, 6.0),
        (coord["TTS"], 1.3, 2.0),
        (coord["Out"], 0.8, 1.0)
    ]
    for x, y_bot, y_top in active_lifelines:
        rect = patches.Rectangle((x - 0.06, y_bot), 0.12, y_top - y_bot,
                                 edgecolor=p["box_edge"], facecolor="#E0E0E0", linewidth=0.8)
        ax.add_patch(rect)

    for y, from_x, to_x, label, arrow_type, offset_y in steps:
        if arrow_type == "loop":
            # Self loop
            ax.plot([from_x + 0.06, from_x + 0.5, from_x + 0.5, from_x + 0.06],
                    [y, y, y - 0.4, y - 0.4], color=p["arrow"], lw=1.2)
            # Arrow head
            ax.annotate("", xy=(from_x + 0.06, y - 0.4), xytext=(from_x + 0.16, y - 0.4),
                        arrowprops=dict(arrowstyle="-|>", color=p["arrow"], lw=1.2, mutation_scale=8))
            ax.text(from_x + 0.55, y - 0.22, label, fontsize=7, ha='left', va='center', color=p["text"])
        else:
            # Line
            linestyle = "--" if arrow_type == "-->" else "-"
            # Arrow props
            arrow_props = dict(arrowstyle="-|>" if arrow_type == "->" else "->",
                             linestyle=linestyle, color=p["arrow"], lw=1.2, mutation_scale=8)
            ax.annotate("", xy=(to_x, y), xytext=(from_x, y), arrowprops=arrow_props)

            # Label
            mid_x = (from_x + to_x) / 2
            ax.text(mid_x, y + 0.08, label, fontsize=7, ha='center', va='bottom', color=p["text"])

    save_fig(fig, "sequence_diagram.png")

# ==========================================
# 5. UML USE CASE DIAGRAM
# ==========================================
def draw_use_case_diagram(style):
    p = PALETTES[style]
    fig, ax = plt.subplots(figsize=(15, 10), facecolor=p["bg"])
    ax.set_facecolor(p["bg"])
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 10)
    ax.axis('off')

    title = "GramNet AI System Use Cases"
    if style == "simple":
        ax.text(7.0, 9.6, title, fontsize=15, fontweight='bold', ha='center', color=p["text"])
    else:
        ax.text(7.0, 9.6, title, fontsize=16, fontweight='bold', ha='center', color=p["box_edge"])

    # System boundary box
    rect_boundary = patches.Rectangle((1.8, 0.4), 10.5, 8.8, linewidth=1.8,
                                     edgecolor=p["box_edge"], facecolor="none")
    ax.add_patch(rect_boundary)
    ax.text(7.0, 8.9, "GramNet AI System", fontsize=11, fontweight='bold', ha='center', color=p["text"])

    # Draw Actor stick figures
    def draw_actor(x, y, name):
        circle = patches.Circle((x, y + 0.45), 0.18, linewidth=1.5, edgecolor=p["box_edge"], facecolor=p["bg"])
        ax.add_patch(circle)
        ax.plot([x, x], [y + 0.27, y - 0.2], color=p["box_edge"], lw=1.5) # spine
        ax.plot([x - 0.3, x + 0.3], [y + 0.1, y + 0.1], color=p["box_edge"], lw=1.5) # arms
        ax.plot([x, x - 0.2], [y - 0.2, y - 0.65], color=p["box_edge"], lw=1.5) # left leg
        ax.plot([x, x + 0.2], [y - 0.2, y - 0.65], color=p["box_edge"], lw=1.5) # right leg
        ax.text(x, y - 0.95, name, fontsize=9.5, fontweight='bold', ha='center', color=p["text"])

    draw_actor(0.8, 5.0, "Student")
    draw_actor(13.0, 5.0, "Administrator")

    # Use Cases (ellipse shapes)
    student_color = "#E2F0D9" if style == "polished" else p["box_bg"]
    system_color = "#DDEBF7" if style == "polished" else p["box_bg"]
    admin_color = "#FCE4D6" if style == "polished" else p["box_bg"]
    border_color = p["box_edge"]

    use_cases = [
        # Student Use Cases (X = 3.0)
        (8.1, 3.0, "Login / Register", 1.8, 0.55, student_color),
        (7.2, 3.0, "Ask Questions\n(Text Input)", 1.8, 0.55, student_color),
        (6.3, 3.0, "Ask Questions\n(Voice Input)", 1.8, 0.55, student_color),
        (5.4, 3.0, "Scan Worksheet\n(Camera OCR)", 1.8, 0.55, student_color),
        (4.5, 3.0, "Receive Responses\n(Multiple Languages)", 1.8, 0.55, student_color),
        (3.6, 3.0, "Attempt Quizzes\n(Adaptive)", 1.8, 0.55, student_color),
        (2.7, 3.0, "Access Educational\nMaterials", 1.8, 0.55, student_color),
        (1.8, 3.0, "Listen to Audio\nResponses", 1.8, 0.55, student_color),

        # System Internal Use Cases - Column A (X = 7.0)
        (7.2, 7.0, "Process Query\n(Translate, NLP,\nRetrieve)", 1.8, 0.65, system_color),
        (3.6, 7.0, "Translate to User\nPreferred Language", 1.8, 0.55, system_color),
        (1.4, 7.0, "Text-to-Speech\n(TTS)", 1.8, 0.55, system_color),

        # System Internal Use Cases - Column B (X = 9.2)
        (5.4, 9.2, "Retrieve Relevant\nInformation (RAG)", 1.8, 0.55, system_color),
        (3.6, 9.2, "Generate Response\n(TinyLlama)", 1.8, 0.55, system_color),

        # Administrator Use Cases (X = 11.4)
        (8.1, 11.4, "Manage Educational\nDatasets", 1.8, 0.55, admin_color),
        (6.9, 11.4, "Update Learning\nContent", 1.8, 0.55, admin_color),
        (5.7, 11.4, "Monitor System\nPerformance", 1.8, 0.55, admin_color),
        (4.5, 11.4, "Maintain User &\nQuiz Records", 1.8, 0.55, admin_color)
    ]

    use_case_map = {}
    for idx, (y, x, text, w, h, fc) in enumerate(use_cases):
        ellipse = patches.Ellipse((x, y), w, h, linewidth=1.5, edgecolor=border_color, facecolor=fc)
        ax.add_patch(ellipse)
        ax.text(x, y, text, fontsize=7.2, ha='center', va='center', color=p["text"])
        use_case_map[idx] = (x, y, w, h)

    # Actor Connections (Solid lines)
    # Student (at x=0.8, y=5.0) -> Connect to first 8 use cases
    for i in range(8):
        uc_x, uc_y, uc_w, uc_h = use_case_map[i]
        ax.plot([1.0, uc_x - uc_w/2], [5.0, uc_y], color=p["line"], lw=1.2)

    # Administrator (at x=13.0, y=5.0) -> Connect to admin use cases (indices 13 to 16)
    for i in range(13, 17):
        uc_x, uc_y, uc_w, uc_h = use_case_map[i]
        ax.plot([12.8, uc_x + uc_w/2], [5.0, uc_y], color=p["line"], lw=1.2)

    # Include relations (Dashed lines with <<include>>)
    def draw_include(from_idx, to_idx, label_pos=0.4, va='bottom', ha='center', offset_x=0.0, offset_y=0.08):
        fx, fy, fw, fh = use_case_map[from_idx]
        tx, ty, tw, th = use_case_map[to_idx]
        # Calculate intersection points approximately
        dx = tx - fx
        dy = ty - fy
        dist = (dx**2 + dy**2)**0.5

        # Calculate points slightly offset from center
        start_x = fx + (dx/dist) * (fw/2)
        start_y = fy + (dy/dist) * (fh/2)
        end_x = tx - (dx/dist) * (tw/2)
        end_y = ty - (dy/dist) * (th/2)

        # Draw dashed line with arrow
        ax.annotate("", xy=(end_x, end_y), xytext=(start_x, start_y),
                    arrowprops=dict(arrowstyle="->", color=p["line"], lw=1.0, linestyle="--"))

        # Place the <<include>> label along the path
        lx = start_x + label_pos * (end_x - start_x) + offset_x
        ly = start_y + label_pos * (end_y - start_y) + offset_y
        ax.text(lx, ly, "<<include>>", fontsize=6.2, ha=ha, va=va, color=p["text"])

    # Links:
    # Student Use Cases to UC8 (Process Query)
    # Ask Text (1) -> Process Query (8)
    draw_include(1, 8, label_pos=0.45, ha='center', va='bottom', offset_y=0.08)
    # Ask Voice (2) -> Process Query (8)
    draw_include(2, 8, label_pos=0.4, ha='center', va='bottom', offset_y=0.08)
    # Scan Camera (3) -> Process Query (8)
    draw_include(3, 8, label_pos=0.35, ha='center', va='bottom', offset_y=0.08)
    # Receive Responses (4) -> Process Query (8)
    draw_include(4, 8, label_pos=0.3, ha='center', va='bottom', offset_y=0.08)
    # Attempt Quizzes (5) -> Process Query (8)
    draw_include(5, 8, label_pos=0.25, ha='center', va='bottom', offset_y=0.08)

    # Access Materials (6) -> Translate Preferred (9)
    draw_include(6, 9, label_pos=0.45, ha='center', va='bottom', offset_y=0.08)
    # Listen Audio (7) -> TTS (10)
    draw_include(7, 10, label_pos=0.45, ha='center', va='bottom', offset_y=0.08)

    # Internal links:
    # Process Query (8) -> Retrieve RAG (11)
    draw_include(8, 11, label_pos=0.5, ha='left', va='bottom', offset_x=0.05, offset_y=0.08)
    # Process Query (8) -> Translate Preferred (9) [vertical]
    draw_include(8, 9, label_pos=0.5, ha='right', va='center', offset_x=-0.15, offset_y=0)
    # Retrieve RAG (11) -> Generate Response (12) [vertical]
    draw_include(11, 12, label_pos=0.5, ha='left', va='center', offset_x=0.15, offset_y=0)
    # Generate Response (12) -> TTS (10)
    draw_include(12, 10, label_pos=0.5, ha='left', va='bottom', offset_x=0.05, offset_y=0.08)
    # Translate Preferred (9) -> TTS (10) [vertical]
    draw_include(9, 10, label_pos=0.5, ha='right', va='center', offset_x=-0.15, offset_y=0)

    save_fig(fig, "use_case_diagram.png")

# ==========================================
# RUN GENERATION FOR ALL DIAGRAMS
# ==========================================
if __name__ == "__main__":
    print("Generating report diagrams...")
    # Generate Simple Academic Style under standard names
    draw_flow_diagram("simple")
    draw_block_diagram("simple")
    draw_rag_workflow("simple")
    draw_sequence_diagram("simple")
    draw_use_case_diagram("simple")
    print("All report diagrams generated successfully!")
