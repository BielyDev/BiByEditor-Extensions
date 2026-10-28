# Baixar link (download_link)

Extensão do editor: baixa o vídeo (ou só o áudio) de um link, como o YouTube, **sem converter**, e põe o arquivo na pasta **Downloads** da biblioteca. Dá para baixar só um **trecho** (início e fim).

## Instalar
1. Copie esta pasta (`download_link`) para a pasta de extensões do editor: **Editor > Extensions > Manage extensions…** e clique em "Open extensions folder" (é `user://extensions`).
2. Na mesma tela, ligue **Baixar link**. O item aparece em **Editor > Extensions > Download link…**.

## Instalar o yt-dlp (Linux)
```
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ~/.local/share/godot/app_userdata/EditorGodot/extensions/download_link/yt-dlp
chmod +x ~/.local/share/godot/app_userdata/EditorGodot/extensions/download_link/yt-dlp
```
(No Windows: baixe o `yt-dlp.exe` da página de releases do yt-dlp e coloque na pasta da extensão.) Depois abra a janela de novo: ele procura ao abrir.

## Programas necessários
- **ffmpeg** (o mesmo do editor).
- **yt-dlp** para YouTube e outros sites: instale no sistema (PATH) ou coloque o `yt-dlp.exe` / `yt-dlp` dentro desta pasta da extensão ou ao lado do editor.
- Links diretos para um arquivo (.mp4, .mp3...) funcionam só com o ffmpeg (cópia, sem recodificar).
- O YouTube hoje costuma exigir também um executor de JavaScript para o yt-dlp (deno ou node): se o download falhar com aviso sobre isso, instale um e mantenha o yt-dlp atualizado (`yt-dlp -U`).

## Baixar só um trecho
Na janela, preencha **Início** e/ou **Fim** (opcionais). Aceita segundos (`90`), minutos:segundos (`1:30`) ou `1:02:03`, com decimais. Vazio = vai do começo ou até o fim.
- Só o início: baixa dali até o fim. Só o fim: baixa do começo até ali.
- No YouTube e similares o yt-dlp baixa apenas o trecho (com cortes precisos, o que recodifica o começo e o fim do trecho, então pode demorar um pouco mais).
- Em link direto de arquivo, o ffmpeg corta sem recodificar (o corte cai no quadro-chave mais próximo).
- O arquivo ganha o trecho no nome, por exemplo `Titulo [0m10s-1m30s].mp4`. O trecho vale só para aquele download e não fica salvo.

## Biblioteca
Todo download entra na pasta **Downloads** da biblioteca (a pasta é criada se não existir).

## Opções (já vêm prontas para o YouTube)
- **Qualidade:** melhor disponível, 2160p, 1440p, 1080p, 720p, 480p ou só o áudio (em MP3: o editor não lê m4a, aac nem opus; se um download vier nesses formatos, a extensão converte para MP3 sozinha).
- **Vídeo mais compatível** (ligado): H.264 + AAC em MP4, que toca em qualquer lugar (no YouTube vai até 1080p). Desligado, pega a melhor qualidade mesmo em VP9/AV1.
- **Forçar IPv4** (ligado): evita o erro "No route to host" quando o IPv6 da rede não funciona.
- **Cookies do navegador:** só para vídeos que pedem login ou "confirmar que não é um robô". Feche o navegador antes.
- **Salvar em:** pasta dos downloads (padrão: Vídeos/BiByEditor). As opções ficam salvas.
- Rede instável: tenta até 30 vezes, com espera crescente, e baixa em pedaços de 5 MB (o que já veio não se perde numa queda). Se mesmo assim falhar com "No route to host", o problema é a conexão da máquina.
- Só baixa o vídeo do link, nunca a playlist inteira.

Baixe só o que você tem direito de usar: muitos sites proíbem o download nos termos de uso.
