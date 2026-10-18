# Darwin Cards V5.0

## O que mudou

- Contas pelo Supabase Auth; modo visitante permanece disponível.
- Perfil com nome, avatar e banner. GIF e WebP animados são aceitos; o banner recebe degradê esfumaçado escuro na base.
- Baralhos personalizados salvos na conta e escolha do formato (clássico, aleatório ou deck próprio) para a próxima partida.
- Convite de sala por link `?room=CODIGO`, com botão de copiar; quem abre o convite entra pelo fluxo normal de apelido ou login.
- Identificador visual fixo `V5.0` no canto superior esquerdo.

## Ativar Supabase

A URL do projeto e a chave pública `sb_publishable_` já estão configuradas no código V5.0. Você não precisa digitá-las no site. O código usa `supabase-js` no navegador; a chave publishable foi feita para uso público em aplicações web, mas as tabelas precisam das políticas RLS deste pacote. Nunca substitua por uma chave `sb_secret_` ou `service_role`.

Para habilitar Auth, perfis, decks e mídia, execute `supabase-v5.sql` no **SQL Editor** do seu projeto Supabase. Depois publique o pacote completo no Vercel. O cadastro e o login serão liberados quando o SQL estiver aplicado.

GIF/WebP podem ser animados. Upload máximo: 8 MB por imagem. O bucket `profile-media` é público para que avatars/banners possam ser exibidos; as políticas permitem que uma pessoa altere arquivos apenas na própria pasta. Decks e perfis são protegidos por RLS e grants explícitos.

## Salas por link

Crie uma sala e compartilhe o link exibido. Ao abrir o endereço, o convidado é levado ao lobby e o código é aplicado automaticamente depois de entrar como visitante ou autenticar. A sala continua temporária e usa a sinalização já configurada no projeto; não há tabela SQL de salas.

## Validação

O código V5.0 foi revisado estaticamente e testado no navegador local. O fluxo real de e-mail, upload, banco e salas na produção depende de executar o SQL e publicar o pacote; não foi publicado nem conectado a uma conta externa nesta tarefa.
