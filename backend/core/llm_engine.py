from llama_cpp import Llama

llm = Llama(
    model_path="models/tinyllama.gguf",
    n_ctx=2048
)

def generate_answer(prompt, max_tokens=200):
    output = llm(
        prompt,
        max_tokens=max_tokens,
        temperature=0.3,
        stop=["Question:", "Context:"]
    )
    return output["choices"][0]["text"].strip()
