from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import torch

class Translator:
    def __init__(self):
        print("🧠 Loading translation model (NLLB)...")
        self.tokenizer = AutoTokenizer.from_pretrained("facebook/nllb-200-distilled-600M")
        self.model = AutoModelForSeq2SeqLM.from_pretrained(
            "facebook/nllb-200-distilled-600M",
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            device_map="auto"
        )
        print("✅ Translation model loaded")

    def translate(self, text, src_lang, tgt_lang):
        self.tokenizer.src_lang = src_lang

        inputs = self.tokenizer(text, return_tensors="pt").to(self.model.device)
        forced_bos = self.tokenizer.convert_tokens_to_ids(tgt_lang)

        output = self.model.generate(
            **inputs,
            forced_bos_token_id=forced_bos,
            max_new_tokens=128
        )

        return self.tokenizer.decode(output[0], skip_special_tokens=True)
