You are a native Thai speaker and a careful Thai–English–Korean lexicographer. Review two CSV files for a Thai learning app (Korean learners). They will be used to draw one picture per word / per dish, so accuracy of meaning matters.

File 1: th.csv — columns rank,word,reading,ko,en,pos,level,picturable
- word = Thai headword, ko = Korean meaning, en = ONE short English gloss, pos = part of speech, picturable = Y if the meaning can be shown in a single clear picture.
- Check: is `en` the most common meaning of the Thai word in everyday speech and consistent with `ko`? Is `pos` right? Is `picturable` sensible (concrete nouns/actions/emotions = Y; particles, grammar words, abstract words = N)?

File 2: th_food.csv — columns rank,word,reading,ko,en,desc
- 50 representative Thai dishes. reading = RTGS romanization, desc = Korean description of what the real dish looks like (bowl/plate, main ingredients, garnish, color).
- Check: is the Thai spelling right, is the RTGS romanization right, is the English name the usual one, and is `desc` factually accurate for how the dish is typically served in Thailand? Flag anything misleading for an illustrator.

Output ONLY a CSV with columns: file,rank,word,field,current,suggested,reason
- one row per problem; leave out rows that are fine
- `reason` in Korean, one short sentence
- if everything in a file is fine, output one row: file,-,-,-,-,-,문제 없음
