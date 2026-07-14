from core.llm_engine import generate_answer
from core.retriever import retrieve
import sympy as sp
import gc   #  ADD HERE (top of file)

def solve_math(query):
    try:
        if any(char.isdigit() for char in query):
            return str(sp.sympify(query))
        return None
    except:
        return None

GLOSSARY_FALLBACK = {
    "gravity": "Gravity is the invisible force that pulls objects toward each other. It is what keeps our feet on the ground and makes things fall when you drop them.",
    "photosynthesis": "Photosynthesis is the process by which green plants and some other organisms use sunlight, water, and carbon dioxide to synthesize nutrients (food), releasing oxygen as a byproduct.",
    "electricity": "Electricity is a form of energy resulting from the existence of charged particles (such as electrons or protons), either statically as an accumulation of charge or dynamically as a current.",
    "electric": "Electricity is a form of energy resulting from the existence of charged particles (such as electrons or protons), either statically as an accumulation of charge or dynamically as a current.",
    "current": "Electric current is the rate of flow of electric charge (electrons) through a conducting medium, measured in Amperes.",
    "pollen": "Pollen grains are microscopic powder-like grains produced by the male organs of flowers (anthers) that carry sperm cells for plant reproduction.",
    "circle": "A circle is a round, two-dimensional shape where all points on the curved outer boundary are at an equal distance (radius) from a fixed center point.",
    "prime": "A prime number is a whole number greater than 1 that cannot be formed by multiplying two smaller whole numbers; it has only two factors: 1 and itself (e.g., 2, 3, 5, 7).",
    "triangle": "A triangle is a closed two-dimensional shape with three straight sides, three corners (vertices), and three angles that add up to 180 degrees.",
    "area": "Area is the measurement of the size or extent of a two-dimensional surface, expressed in square units (like square centimeters or square meters).",
    "force": "A force is a push or a pull acting upon an object resulting from its interaction with another object. It can change the state of motion or shape of an object (measured in Newtons).",
    "energy": "Energy is the quantitative property that must be transferred to a body or physical system to perform work on, or to heat, the body. It cannot be created or destroyed, only transformed.",
    "speed": "Speed is the rate at which an object covers distance. It is a scalar quantity calculated by dividing the total distance traveled by the time taken.",
    "velocity": "Velocity is the speed of an object in a specific direction. It is a vector quantity, meaning it has both magnitude (speed) and direction.",
    "acceleration": "Acceleration is the rate at which an object's velocity changes over time. It can refer to speeding up, slowing down, or changing direction.",
    "atom": "An atom is the basic building block of chemistry and the smallest unit of ordinary matter that forms a chemical element, consisting of protons, neutrons, and electrons.",
    "molecule": "A molecule is a group of two or more atoms chemically bonded together, representing the smallest fundamental unit of a chemical compound that can take part in a chemical reaction.",
    "cell": "A cell is the structural, functional, and biological unit of all living organisms. It is often referred to as the building block of life.",
    "tissue": "A tissue is a group of similar cells working together to perform a specific function in an organism (e.g., muscle tissue, nervous tissue).",
    "light": "Light is a form of electromagnetic radiation that can be detected by the human eye, traveling in straight lines and enabling us to see the world.",
    "reflection": "Reflection is the bouncing back of light, sound, or heat waves when they hit a surface that they cannot pass through, like light bouncing off a mirror.",
    "refraction": "Refraction is the bending of light waves as they pass from one transparent medium to another of different density, caused by a change in their speed.",
    "acid": "An acid is a chemical substance that neutralizes alkalis, turns blue litmus paper red, has a sour taste, and has a pH value of less than 7.",
    "base": "A base is a chemical substance that reacts with acids to form salts, turns red litmus paper blue, feels slippery, and has a pH value greater than 7.",
    "metal": "Metals are elements that are typically hard, shiny, malleable, ductile, and good conductors of heat and electricity (e.g., iron, copper, gold).",
    "nonmetal": "Nonmetals are elements that lack metallic properties; they are typically poor conductors of heat and electricity, brittle in solid state, and can be gases, liquids, or solids.",
    "chemical": "A chemical is any substance with a distinct molecular composition, produced by or used in a chemical process.",
    "reaction": "A chemical reaction is a process in which one or more substances (reactants) are chemically rearranged and converted into different substances (products).",
    "equation": "A chemical or mathematical equation is a symbolic representation of a relationship, reaction, or equality between two sides (left and right).",
    "fraction": "A fraction represents a part of a whole, consisting of a numerator (top number) and a denominator (bottom number) separated by a dividing line.",
    "decimal": "A decimal is a fraction written in a special form using a decimal point, based on powers of ten (e.g., 0.5 represents five-tenths).",
    "ratio": "A ratio is a comparison of two quantities by division, indicating how many times one number contains another (expressed as a:b).",
    "proportion": "Proportion is an equation that states that two ratios are equal (e.g., a/b = c/d).",
    "algebra": "Algebra is a branch of mathematics in which arithmetic relations are generalized using letters or symbols to represent unknown numbers in equations.",
    "geometry": "Geometry is a branch of mathematics concerned with the properties, measurement, and relationships of points, lines, angles, surfaces, and solids.",
    "quadrilateral": "A quadrilateral is a flat, two-dimensional geometric shape that has four straight sides, four vertices, and interior angles summing up to 360 degrees.",
    "rectangle": "A rectangle is a four-sided flat shape where all interior angles are right angles (90 degrees) and opposite sides are equal and parallel.",
    "square": "A square is a flat shape with four equal straight sides and four right angles (90 degrees).",
    "number": "A number is an arithmetical value, expressed by a word, symbol, or figure, representing a particular quantity used in counting and calculating.",
    "integer": "An integer is a whole number (not a fractional number) that can be positive, negative, or zero (e.g., -3, 0, 5).",
    "polynomial": "A polynomial is a mathematical expression consisting of variables and coefficients, involving only the operations of addition, subtraction, multiplication, and non-negative integer exponents.",
    "trigonometry": "Trigonometry is a branch of mathematics that studies relationships between side lengths and angles of triangles, particularly right-angled triangles.",
    "angle": "An angle is the space (measured in degrees) between two intersecting lines or surfaces at or close to the point where they meet.",
    "side": "A side is a line segment that forms part of the boundary of a geometric shape.",
    "perimeter": "Perimeter is the continuous line forming the boundary of a closed geometric shape, calculated by adding the lengths of all its sides.",
    "circumference": "Circumference is the distance around the outer boundary of a circle (its perimeter), calculated using the formula C = 2πr.",
    "diameter": "A diameter is any straight line segment that passes through the center of the circle and whose endpoints lie on the circle, equal to twice the radius.",
    "radius": "A radius is a straight line segment from the center of a circle or sphere to its outer boundary or circumference, equal to half of the diameter.",
    "volume": "Volume is the amount of three-dimensional space enclosed by a closed boundary, expressed in cubic units (like cubic centimeters or cubic meters).",
    "temperature": "Temperature is a physical property of matter that quantitatively expresses the hotness or coldness of an object, measured with a thermometer in Celsius, Fahrenheit, or Kelvin.",
    "heat": "Heat is the transfer of kinetic energy from one medium or object to another due to a difference in temperature, flowing from hotter to cooler bodies.",
    "pressure": "Pressure is the force applied perpendicular to the surface of an object per unit area over which that force is distributed (measured in Pascals).",
    "sound": "Sound is a vibration that propagates as an acoustic wave through a transmission medium such as a gas, liquid or solid.",
    "magnet": "A magnet is an object or material that produces a magnetic field, attracting iron and other magnetic materials and having north and south poles.",
    "plants": "Plants are multicellular living organisms belonging to the kingdom Plantae, characterized by photosynthesis and cell walls containing cellulose.",
    "food": "Food is any nutritious substance that people or animals eat or drink, or that plants absorb, in order to maintain life and growth."
}

def tutor_response(query, chunks, index):

    #  STEP 1: Math handling
    math_result = solve_math(query)
    if math_result:
        return f"Answer: {math_result}"

    #  STEP 2: Retrieval
    retrieved_chunks, similarity_scores = retrieve(query, chunks, index)

    # Debug prints showing retrieval details
    print("QUESTION:", query)
    print("TOP_K:", len(retrieved_chunks))
    print("SIMILARITY SCORES:", similarity_scores)
    print("RETRIEVED CHUNKS:")
    for chunk in retrieved_chunks:
        print(chunk)
        print("-" * 50)

    # Increased context string length from 2000 to 6000 characters
    context = "\n".join(retrieved_chunks[:5])
    context = context[:6000]

    answer = ""
    prompt = ""
    # If we have context, try textbook-based RAG first
    if context.strip():
        # Prompt (TinyLlama Chat Format - less restrictive, syllabus-focused)
        prompt = f"""<|system|>
You are a helpful science and math AI tutor. Answer the student's question clearly using the provided context. If the context does not contain the answer but is highly related, use your knowledge to explain simply. If the answer cannot be inferred at all, say "I don't know". Explain briefly.</s>
<|user|>
Context:
{context}

Question:
{query}</s>
<|assistant|>
"""
        answer = generate_answer(prompt)
        print("FINAL PROMPT:")
        print(prompt)
        print("RAW MODEL RESPONSE:")
        print(answer)

    # Robust fallback detection for model outputs indicating failure/inability to answer
    fallback_phrases = [
        "i don't know",
        "don't know",
        "do not know",
        "context does not provide",
        "context does not contain",
        "not present in the context",
        "no information",
        "cannot find",
        "unspecified"
    ]
    is_fallback = not context.strip() or not answer.strip() or any(phrase in answer.lower() for phrase in fallback_phrases)

    # If no context was found OR LLM fallback detected, use local glossary safety net or school teacher fallback
    if is_fallback:
        query_lower = query.lower()
        matched_definition = None
        matched_key = ""

        # Match longer terms first (e.g. 'electric current' over 'current')
        for key in sorted(GLOSSARY_FALLBACK.keys(), key=len, reverse=True):
            if key in query_lower:
                matched_definition = GLOSSARY_FALLBACK[key]
                matched_key = key
                break

        if matched_definition:
            print(f" [FALLBACK] RAG failed/fallback detected. Used local glossary fallback for '{matched_key}'")
            answer = matched_definition
        else:
            print(f" [FALLBACK] RAG failed or fallback detected. Using general school-teacher fallback for: {query}")
            fallback_prompt = f"""<|system|>
You are a helpful science, math, and English school teacher for Class 6 to 10. Answer the student's question in a simple, clear, and accurate way. Explain briefly.</s>
<|user|>
Question:
{query}</s>
<|assistant|>
"""
            answer = generate_answer(fallback_prompt)

    #  FREE MEMORY HERE (MOST IMPORTANT)
    del retrieved_chunks
    del context
    gc.collect()

    return answer
