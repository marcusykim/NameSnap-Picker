import fs from "node:fs";
import path from "node:path";

const OUTPUT = path.join(import.meta.dirname, "streamer-outreach-100.md");
const SITE = "https://getnamesnap.web.app";

// Snapshot from TwitchMetrics' "Most Followed" pages on 2026-08-22.
// Categories are the most recently observed category, not a permanent creator label.
const channels = [
  [1,"KaiCenat","21,663,283","EN","Minecraft","P1","challenge","Big-event chat moments and Minecraft challenges make the wheel feel native to the show."],
  [2,"ibai","20,332,197","ES","League of Legends","P1","teams","Sus grandes eventos y comunidades de League of Legends encajan muy bien con selecciones en vivo."],
  [3,"Ninja","19,241,454","EN","Fortnite","P1","squad","Fortnite customs and community giveaways are a direct fit for a visible, fair pick."],
  [4,"auronplay","17,028,371","ES","Just Chatting","P2","prompts","Sus segmentos de conversación pueden convertir la elección de retos del chat en un momento visual."],
  [5,"Rubius","16,517,479","ES","Variety","P1","challenge","Su formato variado permite usar la ruleta para decidir retos, juegos o participantes."],
  [6,"xQc","12,535,892","EN","Variety","P2","challenge","Fast-moving variety streams could turn a routine chat choice into a memorable wheel moment."],
  [7,"TheGrefg","12,290,432","ES","Variety","P1","challenge","Sus eventos y retos con la comunidad son ideales para una selección visible y rápida."],
  [8,"juansguarnizo","11,665,963","ES","Just Chatting","P1","prompts","Su comunidad de conversación puede usar la ruleta para preguntas, retos y sorteos."],
  [9,"Tfue","11,536,564","EN","Fortnite","P2","squad","Fortnite viewers already understand high-stakes reveals, so a wheel pick fits naturally."],
  [10,"shroud","11,288,399","EN","Halo: Campaign Evolved","P2","challenge","Precision-game audiences would appreciate a clean, transparent way to pick participants or challenges."],
  [11,"Jynxzi","11,176,257","EN","Rainbow Six Siege","P1","squad","Rainbow Six customs and community challenges are a strong fit for an on-screen randomizer."],
  [12,"ElMariana","11,122,614","ES","Just Chatting","P1","prompts","El ritmo de sus directos puede convertir una elección del chat en un momento de suspenso."],
  [13,"pokimane","9,451,007","EN","Just Chatting","P1","prompts","Community prompts, viewer games, and giveaways all fit a friendly, transparent wheel reveal."],
  [14,"sodapoppin","8,966,415","EN","Mistfall Hunter","P2","challenge","Long-running variety and game challenges give the wheel several natural on-stream roles."],
  [15,"caseoh_","8,956,470","EN","Just Chatting","P1","challenge","Big reaction moments and chat-led challenges are exactly where a dramatic wheel earns its keep."],
  [16,"Clix","8,649,181","EN","Fortnite","P1","squad","Fortnite customs, squads, and giveaways provide an immediate use case."],
  [17,"alanzoka","8,098,020","PT","Variety","P1","challenge","O formato variado do canal combina com uma roleta para desafios, jogos e participantes."],
  [18,"TimTheTatman","7,613,492","EN","Marvel Rivals","P1","teams","Team games and community giveaways make a fair visual draw easy to demonstrate."],
  [19,"Riot Games","7,362,395","EN","League of Legends","TEAM","event","Official esports broadcasts could use a branded-neutral picker for fan segments and event giveaways."],
  [20,"Myth","7,263,160","EN","Cyberpunk 2077","P2","challenge","Variety gameplay and community segments offer several low-friction ways to test the wheel."],
  [21,"Coringa","7,233,702","PT","Virtual Casino","HOLD","giveaway","A audiência é grande, mas a categoria recente de cassino torna esta campanha escolar uma incompatibilidade de marca."],
  [22,"SypherPK","7,226,780","EN","Fortnite","P1","squad","Fortnite education, customs, and community play make the fair-pick story especially clear."],
  [23,"AriGameplays","7,217,338","ES","Just Chatting","P1","prompts","Su comunidad puede convertir preguntas, retos y sorteos en una revelación divertida."],
  [24,"Mongraal","7,198,299","EN","Fortnite","P1","squad","Competitive Fortnite viewers are a natural audience for randomly selected customs and squads."],
  [25,"rivers_gg","7,082,116","ES","Just Chatting","P1","prompts","Sus segmentos con el chat pueden usar la ruleta para elegir retos o participantes con transparencia."],
  [26,"ESLCS","6,803,356","EN","Counter-Strike","TEAM","event","Tournament broadcasts could use NameSnap for fan activations without touching competitive outcomes."],
  [27,"NICKMERCS","6,775,370","EN","Apex Legends","P2","squad","Apex squads and community events give the wheel a clear role in selecting viewers or challenges."],
  [28,"Quackity","6,630,285","EN","Just Chatting","P1","prompts","Interactive chat segments and a younger-skewing creative audience make NameSnap highly relevant."],
  [29,"summit1g","6,407,395","EN","Counter-Strike","P2","challenge","A veteran FPS community can use a simple wheel for viewer picks, maps, or offbeat challenges."],
  [30,"Fortnite","6,402,855","EN","Fortnite","TEAM","event","The official Fortnite channel could use it only for clearly separate fan giveaways or community segments."],
  [31,"IShowSpeed","6,053,336","EN","Minecraft","P2","challenge","High-energy Minecraft and audience moments would make the wheel reveal instantly understandable."],
  [32,"AMOURANTH","6,038,571","EN","IRL","HOLD","giveaway","The channel's adult positioning conflicts with the classroom-facing campaign; do not use the student angle."],
  [33,"moistcr1tikal","5,966,290","EN","Variety","P2","challenge","Deadpan reactions plus a deliberately overdramatic wheel could make a strong comedy beat."],
  [34,"Squeezie","5,882,047","FR","VALORANT","P1","squad","Les défis VALORANT et les grands moments communautaires se prêtent bien à un tirage visible."],
  [35,"NickEh30","5,801,315","EN","Fortnite","P1","squad","A family-friendly Fortnite community is one of the strongest fits for giveaways and classroom crossover."],
  [36,"MontanaBlack88","5,761,430","DE","IRL","HOLD","giveaway","Die große Reichweite ist attraktiv, aber die erwachsene Markenpositionierung passt nicht zur Schulkampagne."],
  [37,"elded","5,680,919","ES","Variety","P2","challenge","Su contenido variado permite probar la ruleta con retos, juegos o sorteos."],
  [38,"loltyler1","5,501,863","EN","League of Legends","P2","teams","League team picks and a loud wheel reveal could become a compact recurring bit."],
  [39,"Bugha","5,482,981","EN","Slots","HOLD","squad","Bugha's Fortnite identity is a fit, but the current Slots category requires a fresh brand-safety check before outreach."],
  [40,"Tubbo","5,237,852","EN","Variety","P1","challenge","Collaborative games, community prompts, and younger viewers make the tool feel naturally useful."],
  [41,"buster","5,215,375","RU","Just Chatting","P2","prompts","Разговорные эфиры позволяют превратить выбор вопроса или участника в заметный момент."],
  [42,"stableronaldo","5,197,763","EN","Just Chatting","P2","challenge","Chat-driven challenges and reaction moments are a straightforward wheel use case."],
  [43,"QuackityToo","4,938,388","ES","Just Chatting","P1","prompts","El canal en español puede usar la ruleta para preguntas, invitados o retos elegidos por la comunidad."],
  [44,"RocketLeague","4,879,162","EN","Rocket League","TEAM","event","The official channel could use it for fan activations, not match or bracket decisions."],
  [45,"GeorgeNotFound","4,776,056","EN","Just Chatting","P1","prompts","A Minecraft-rooted community and conversational format make challenge and participant picks easy to stage."],
  [46,"SLAKUNTV","4,694,954","ES","Variety","P2","challenge","El contenido variado ofrece muchas oportunidades para elegir retos o participantes al azar."],
  [47,"Gotaga","4,667,090","FR","Variety","P1","challenge","Les formats variés et communautaires permettent d'intégrer la roue sans interrompre le direct."],
  [48,"MrSavage","4,650,866","EN","Fortnite","P1","squad","Fortnite customs and viewer challenges are an immediate, credible fit."],
  [49,"dakotaz","4,632,586","EN","Fortnite","P1","squad","A long-established Fortnite community gives NameSnap a familiar giveaway and customs context."],
  [50,"IlloJuan","4,617,326","ES","Just Chatting","P1","prompts","La conversación con la comunidad puede convertir la ruleta en un recurso recurrente para retos y preguntas."],
  [51,"TenZ","4,596,229","EN","VALORANT","P1","squad","VALORANT viewer teams, agents, and challenge picks are ideal for a transparent wheel."],
  [52,"elxokas","4,420,894","ES","League of Legends","P2","teams","League of Legends permite usar la ruleta para equipos, roles o retos de la comunidad."],
  [53,"DrLupo","4,388,250","EN","Escape from Tarkov","P1","giveaway","Charity streams and community giveaways make fairness and clear disclosure especially valuable."],
  [54,"Gaules","4,316,202","PT","Project Zomboid","P1","challenge","A comunidade grande e participativa pode usar a roleta para desafios, equipes e sorteios."],
  [55,"Philza","4,286,019","EN","Minecraft","P1","challenge","Minecraft build prompts, goals, and community names are a natural classroom-friendly crossover."],
  [56,"RanbooLive","4,259,851","EN","Variety","P1","challenge","Creative variety streams and community games make NameSnap a strong audience-participation prop."],
  [57,"MissaSinfonia","4,231,229","ES","Minecraft","P1","challenge","Minecraft permite elegir construcciones, retos o participantes de una forma visual y divertida."],
  [58,"s1mple","4,152,816","EN","Counter-Strike","P2","challenge","An FPS audience could use it for community players, maps, or challenge constraints."],
  [59,"Symfuhny","4,122,226","EN","Marvel Rivals","P1","teams","Hero teams and community challenges give the wheel several obvious uses."],
  [60,"easportsfc","4,047,260","EN","EA Sports FC 26","TEAM","event","The official EA Sports FC channel could use it for fan segments, creator matches, or giveaways."],
  [61,"Fanum","3,983,349","EN","Just Chatting","P1","prompts","Community-led IRL and chat moments can turn a simple choice into a suspenseful recurring segment."],
  [62,"Trymacs","3,943,948","DE","IRL","P1","challenge","IRL-Challenges und Community-Aktionen lassen sich mit einem sichtbaren Zufallsmoment gut verbinden."],
  [63,"Ludwig","3,785,103","EN","Variety","P1","event","Competition formats and meticulously produced live events make the wheel a particularly credible fit."],
  [64,"bratishkinoff","3,777,517","RU","Just Chatting","P2","prompts","Разговорный формат подходит для выбора вопросов, заданий и участников прямо на экране."],
  [65,"Sykkuno","3,740,420","EN","Variety","P1","challenge","Social games and a warm community tone fit a low-pressure, fair random pick."],
  [66,"Castro_1021","3,715,330","EN","Variety","P1","teams","Football games, pack-style reveals, and community challenges all benefit from a visible draw."],
  [67,"PaulinhoLOKObr","3,701,953","PT","Variety","P2","challenge","O conteúdo variado pode transformar escolhas do chat em um quadro rápido com a roleta."],
  [68,"Cellbit","3,617,918","PT","Welcome to the Game III","P1","prompts","Mistério e narrativa combinam com uma roleta para escolher pistas, perguntas ou participantes."],
  [69,"Joe_Bartolozzi","3,555,485","EN","Just Chatting","P2","prompts","Reaction-heavy chat segments can make the exaggerated wheel reveal part of the joke."],
  [70,"Staryuuki","3,547,522","ES","Just Chatting","P1","prompts","La comunidad puede usar la ruleta para preguntas, retos y sorteos sin pedir cuentas a los espectadores."],
  [71,"Agent00","3,509,657","EN","Just Chatting","P1","prompts","Sports and community conversations create easy opportunities for predictions, prompts, and giveaways."],
  [72,"Duke","3,465,662","EN","Just Chatting","P2","challenge","Challenge-driven chat moments could turn the wheel into a quick recurring bit."],
  [73,"Lacy","3,342,173","EN","Just Chatting","P2","challenge","A younger, fast-moving chat audience would immediately understand a wheel-based challenge or giveaway."],
  [74,"tarik","3,309,429","EN","VALORANT","P1","squad","VALORANT watch parties, viewer teams, and agent challenges provide several clean integrations."],
  [75,"Rainbow6","3,285,580","EN","Rainbow Six Siege","TEAM","event","The official channel could use it for fan giveaways or side segments, never competitive rulings."],
  [76,"kingsleague","3,278,450","ES","Kings League","TEAM","event","Una retransmisión deportiva puede usar la ruleta en activaciones de fans y sorteos, no en decisiones competitivas."],
  [77,"VEGETTA777","3,247,896","ES","Minecraft","P1","challenge","Minecraft y una comunidad de larga trayectoria encajan con retos, construcciones y sorteos familiares."],
  [78,"Alexby11","3,199,157","ES","Minecraft","P1","challenge","Minecraft permite convertir la elección de retos o participantes en un momento claro para la audiencia."],
  [79,"Aydan","3,193,500","EN","Call of Duty: Warzone","P2","squad","Warzone squads, loadouts, and viewer challenges are a direct wheel use case."],
  [80,"rayasianboy","3,181,064","EN","IRL","P2","challenge","IRL tasks and chat decisions could become a simple on-screen spin segment."],
  [81,"deepins02","3,147,577","RU","Just Chatting","P2","prompts","Интерактив с чатом подходит для выбора вопросов, заданий и участников через колесо."],
  [82,"Cristinini","3,144,277","ES","Cities: Skylines II","P1","challenge","La construcción y la creatividad permiten elegir barrios, reglas o retos con la ruleta."],
  [83,"Papaplatte","3,140,857","DE","Variety","P1","challenge","Variety- und Community-Formate bieten viele natürliche Einsätze für ein sichtbares Glücksrad."],
  [84,"Jelty","3,093,612","ES","Fortnite","P1","squad","Fortnite ofrece un uso inmediato para lobbies, escuadras y sorteos con la comunidad."],
  [85,"HasanAbi","3,069,233","EN","Just Chatting","HOLD","prompts","The political and mature editorial context is a weak fit for the student/classroom campaign."],
  [86,"cloakzy","3,050,702","EN","Mistfall Hunter","P2","challenge","FPS and variety challenges can use the wheel for maps, squads, or viewer picks."],
  [87,"Loserfruit","3,044,223","EN","Fortnite","P1","squad","A colorful Fortnite community and friendly giveaway format are an excellent product match."],
  [88,"LIRIK","2,997,730","EN","Variety","P2","challenge","Variety streams can use one neutral tool for game, challenge, and community choices."],
  [89,"ohnePixel","2,989,086","EN","Counter-Strike","HOLD","giveaway","The Counter-Strike audience fits, but skins/gambling adjacency needs a manual brand-safety check."],
  [90,"LOLITOFDEZ","2,973,284","ES","Rust","P2","teams","Rust permite elegir equipos, roles y retos de la comunidad de forma transparente."],
  [91,"aXoZer","2,951,145","ES","Minecraft","P1","challenge","Minecraft encaja con una ruleta para construcciones, reglas y participantes."],
  [92,"Luzu","2,945,608","ES","Minecraft","P1","challenge","La comunidad de Minecraft puede usar la rueda para retos, equipos y sorteos familiares."],
  [93,"2xRaKai","2,943,927","EN","Just Chatting","P2","challenge","High-energy chat challenges could make the wheel a recurring audience decision point."],
  [94,"iiTzTimmy","2,928,376","EN","Rainbow Six Siege","P1","squad","FPS challenges, squads, and community events make a fair picker immediately useful."],
  [95,"aceu","2,893,524","EN","Apex Legends","P2","squad","Apex squads, legends, and challenge constraints are natural wheel selections."],
  [96,"Anomaly","2,846,730","EN","Counter-Strike","P2","challenge","Counter-Strike community picks and comedic challenge constraints fit, with a mature-audience review."],
  [97,"PlaqueBoyMax","2,842,913","EN","Just Chatting","P1","event","Music, guest, and community formats can use the wheel for prompts, order, or audience picks."],
  [98,"DisguisedToast","2,830,039","EN","Minecraft","P1","challenge","Social strategy, Minecraft, and group formats are a strong fit for fair participant or challenge selection."],
  [99,"jacksepticeye","2,826,264","EN","Just Chatting","P1","giveaway","Community energy, charity experience, and playful reveals make NameSnap an especially natural fit."],
  [100,"Flight23white","2,807,303","EN","Just Chatting","P2","challenge","Fast-paced audience challenges could use a simple visible wheel for the next pick."],
];

const use = {
  EN: {
    challenge: ["pick the next challenge or participant", "pick the next challenge or participant"],
    teams: ["choose teams, roles, or community participants", "choose teams, roles, or community participants"],
    squad: ["pick viewer squads, custom-lobby spots, or giveaway winners", "pick viewer squads, custom-lobby spots, or giveaway winners"],
    prompts: ["choose chat prompts, questions, or community challenges", "choose chat prompts, questions, or community challenges"],
    event: ["run a fan activation, side segment, or event giveaway", "run a fan activation, side segment, or event giveaway"],
    giveaway: ["select a giveaway winner or community participant", "select a giveaway winner or community participant"],
  },
  ES: {
    challenge: ["elegir el siguiente reto o participante", "elegir el siguiente reto o participante"],
    teams: ["elegir equipos, roles o participantes", "elegir equipos, roles o participantes"],
    squad: ["elegir escuadras, plazas de lobby o ganadores", "elegir escuadras, plazas de lobby o ganadores"],
    prompts: ["elegir preguntas, temas o retos del chat", "elegir preguntas, temas o retos del chat"],
    event: ["hacer una activación de fans, un segmento o un sorteo", "hacer una activación de fans, un segmento o un sorteo"],
    giveaway: ["elegir un ganador o participante de la comunidad", "elegir un ganador o participante de la comunidad"],
  },
  PT: {
    challenge: ["escolher o próximo desafio ou participante", "escolher o próximo desafio ou participante"],
    teams: ["escolher equipes, funções ou participantes", "escolher equipes, funções ou participantes"],
    squad: ["escolher equipes, vagas ou vencedores", "escolher equipes, vagas ou vencedores"],
    prompts: ["escolher perguntas, temas ou desafios do chat", "escolher perguntas, temas ou desafios do chat"],
    event: ["fazer uma ativação de fãs, um quadro ou sorteio", "fazer uma ativação de fãs, um quadro ou sorteio"],
    giveaway: ["selecionar um vencedor ou participante", "selecionar um vencedor ou participante"],
  },
  FR: {
    challenge: ["choisir le prochain défi ou participant", "choisir le prochain défi ou participant"],
    teams: ["choisir des équipes, rôles ou participants", "choisir des équipes, rôles ou participants"],
    squad: ["choisir des équipes, places ou gagnants", "choisir des équipes, places ou gagnants"],
    prompts: ["choisir des questions, sujets ou défis du chat", "choisir des questions, sujets ou défis du chat"],
    event: ["organiser une activation de fans, une séquence ou un concours", "organiser une activation de fans, une séquence ou un concours"],
    giveaway: ["sélectionner un gagnant ou participant", "sélectionner un gagnant ou participant"],
  },
  DE: {
    challenge: ["die nächste Challenge oder Person auszuwählen", "die nächste Challenge oder Person auszuwählen"],
    teams: ["Teams, Rollen oder Community-Teilnehmer auszuwählen", "Teams, Rollen oder Community-Teilnehmer auszuwählen"],
    squad: ["Squads, Plätze oder Gewinner auszuwählen", "Squads, Plätze oder Gewinner auszuwählen"],
    prompts: ["Fragen, Themen oder Chat-Challenges auszuwählen", "Fragen, Themen oder Chat-Challenges auszuwählen"],
    event: ["eine Fan-Aktion, ein Segment oder Giveaway durchzuführen", "eine Fan-Aktion, ein Segment oder Giveaway durchzuführen"],
    giveaway: ["einen Gewinner oder Community-Teilnehmer auszuwählen", "einen Gewinner oder Community-Teilnehmer auszuwählen"],
  },
  RU: {
    challenge: ["выбрать следующее задание или участника", "выбрать следующее задание или участника"],
    teams: ["выбрать команды, роли или участников", "выбрать команды, роли или участников"],
    squad: ["выбрать команды, места или победителей", "выбрать команды, места или победителей"],
    prompts: ["выбрать вопросы, темы или задания из чата", "выбрать вопросы, темы или задания из чата"],
    event: ["провести фан-активацию, рубрику или розыгрыш", "провести фан-активацию, рубрику или розыгрыш"],
    giveaway: ["выбрать победителя или участника сообщества", "выбрать победителя или участника сообщества"],
  },
};

function slug(handle) {
  return handle.toLowerCase().replace(/[^a-z0-9_]/g, "");
}

function publicCode(handle) {
  return `NS-${handle.toUpperCase().replace(/[^A-Z0-9]/g, "")}`;
}

function dm({ handle, lang, category, angle, code, action, team }) {
  if (lang === "ES") return `Hola, equipo de ${handle}: soy Marcus, creador de NameSnap, una ruleta de nombres para el navegador. ${angle} Me gustaría darles acceso web ilimitado gratis y un enlace/código ${code} que pagaría el 40 % de los ingresos web netos atribuidos durante 12 meses. La idea: ${action}. Los espectadores no necesitan cuenta y la lista se queda en el navegador. ¿Les interesaría probarlo en un sorteo o segmento de comunidad? Ustedes conservan el control editorial: ${SITE}`;
  if (lang === "PT") return `Oi, equipe do ${handle}: sou Marcus, criador do NameSnap, uma roleta de nomes no navegador. ${angle} Quero oferecer acesso web ilimitado grátis e um link/código ${code} que pagaria 40% da receita web líquida atribuída por 12 meses. A ideia: ${action}. O público não precisa criar conta e a lista fica no navegador. Topariam testar em um sorteio ou quadro da comunidade? Vocês mantêm total controle editorial: ${SITE}`;
  if (lang === "FR") return `Bonjour l'équipe ${handle}, je suis Marcus, créateur de NameSnap, une roue de noms dans le navigateur. ${angle} Je voudrais vous offrir l'accès web illimité et un lien/code ${code} rémunéré à 40 % du revenu web net attribué pendant 12 mois. L'idée : ${action}. Aucun compte spectateur n'est requis et la liste reste dans le navigateur. Partants pour un essai lors d'un concours ou d'une séquence communautaire ? Vous gardez le contrôle éditorial : ${SITE}`;
  if (lang === "DE") return `Hallo ${handle}-Team, ich bin Marcus, der Entwickler von NameSnap, einem Namensrad im Browser. ${angle} Ich möchte euch kostenlosen, unbegrenzten Webzugang und einen getrackten Link/Code ${code} anbieten, der 12 Monate lang 40 % des zugeordneten Netto-Webumsatzes auszahlt. Die Idee: ${action}. Zuschauer brauchen kein Konto; die Liste bleibt im Browser. Hättet ihr Interesse an einem Test bei einem Giveaway oder Community-Segment? Die redaktionelle Kontrolle bleibt bei euch: ${SITE}`;
  if (lang === "RU") return `Здравствуйте, команда ${handle}! Я Маркус, создатель NameSnap — колеса имен в браузере. ${angle} Хочу дать вам бесплатный безлимитный доступ и ссылку/код ${code} с комиссией 40% от чистой веб-выручки по вашим переходам в течение 12 месяцев. Идея: ${action}. Зрителям не нужен аккаунт, а список остается в браузере. Готовы протестировать это в одном розыгрыше или интерактивной рубрике? Редакционный контроль остается у вас: ${SITE}`;
  const recipient = team ? `${handle} partnerships team` : `${handle} team`;
  return `Hi ${recipient} — I’m Marcus, the maker of NameSnap, a browser-based name wheel. ${angle} I’d like to give you free unlimited web access and a tracked ${code} link that would pay 40% of attributed net web revenue for 12 months. The idea: ${action}. Viewers need no account, and the contestant list stays in the browser. Open to testing it in one giveaway or community segment? You keep full editorial control: ${SITE}`;
}

function readCopy({ handle, lang, code, action }) {
  if (lang === "ES") return `Aviso rápido: NameSnap me dio acceso gratis y puedo ganar una comisión si alguien mejora su plan con ${code}. Hoy lo usaremos para ${action}. Pegamos los nombres elegibles, giramos la rueda y dejamos que elija. Pueden probarlo gratis en getnamesnap.web.app. Si conocen a un profesor, entrenador, club, familia o grupo comunitario que necesite una forma justa de elegir, compártanlo. Si eres menor de 18 años, pide permiso a tu padre, madre o tutor antes de comprar.`;
  if (lang === "PT") return `Aviso rápido: o NameSnap me deu acesso grátis e eu posso ganhar comissão se alguém fizer upgrade com ${code}. Hoje vamos usar para ${action}. Eu colo os nomes elegíveis, giro a roleta e ela faz a escolha. Dá para testar grátis em getnamesnap.web.app. Se você conhece um professor, treinador, clube, família ou grupo comunitário que precisa de uma escolha justa, mostre para eles. Se você tem menos de 18 anos, peça autorização a um responsável antes de comprar.`;
  if (lang === "FR") return `Petite précision : NameSnap m'a offert l'accès et je peux toucher une commission si quelqu'un passe à la version payante avec ${code}. Aujourd'hui, on l'utilise pour ${action}. Je colle les noms éligibles, je lance la roue et elle choisit. Vous pouvez l'essayer gratuitement sur getnamesnap.web.app. Si un professeur, coach, club, proche ou groupe associatif cherche un tirage équitable, montrez-lui. Si vous avez moins de 18 ans, demandez l'accord d'un parent ou tuteur avant tout achat.`;
  if (lang === "DE") return `Kurzer Hinweis: NameSnap hat mir den Zugang kostenlos gegeben, und ich kann eine Provision verdienen, wenn jemand mit ${code} ein Upgrade kauft. Heute nutzen wir es, um ${action}. Ich füge die berechtigten Namen ein, drehe das Rad und lasse es entscheiden. Kostenlos testen könnt ihr es auf getnamesnap.web.app. Wenn Lehrer, Trainer, Vereine, Familien oder Gemeindegruppen ein faires Auswahltool brauchen, zeigt es ihnen. Unter 18 bitte vor einem Kauf Eltern oder Erziehungsberechtigte fragen.`;
  if (lang === "RU") return `Короткое раскрытие: NameSnap дал мне бесплатный доступ, и я могу получить комиссию, если кто-то оформит платную версию по коду ${code}. Сегодня мы используем его, чтобы ${action}. Я вставляю имена допущенных участников, запускаю колесо, и оно выбирает. Бесплатная версия есть на getnamesnap.web.app. Если учителю, тренеру, клубу, семье или общественной группе нужен честный выбор, покажите им сервис. Если вам нет 18 лет, перед покупкой спросите разрешения родителя или опекуна.`;
  return `Quick disclosure: NameSnap gave me free access, and I may earn a commission if someone upgrades with ${code}. We’re using it to ${action}. I paste the eligible names, spin once, and the wheel makes the pick. You can try it free at getnamesnap.web.app. If a teacher, coach, club, family, church, or community group you know needs a fair picker, show them. If you’re under 18, ask a parent or guardian before purchasing.`;
}

function promoDisclaimer(lang, handle) {
  if (lang === "ES") return `Esta es una promoción de ${handle}. Twitch no patrocina ni respalda esta promoción y no es responsable de ella.`;
  if (lang === "PT") return `Esta é uma promoção de ${handle}. A Twitch não patrocina nem endossa esta promoção e não é responsável por ela.`;
  if (lang === "FR") return `Ceci est une promotion de ${handle}. Twitch ne sponsorise ni ne soutient cette promotion et n'en est pas responsable.`;
  if (lang === "DE") return `Dies ist eine Promotion von ${handle}. Twitch sponsert oder unterstützt diese Promotion nicht und ist nicht dafür verantwortlich.`;
  if (lang === "RU") return `Это промоакция канала ${handle}. Twitch не спонсирует и не поддерживает эту промоакцию и не несет за нее ответственности.`;
  return `This is a promotion from ${handle}. Twitch does not sponsor or endorse this promotion and is not responsible for it.`;
}

const sections = channels.map(([rank, handle, followers, lang, category, priority, useKey, angle]) => {
  const channelSlug = slug(handle);
  const code = publicCode(handle);
  const team = priority === "TEAM";
  const [action, spokenAction] = (use[lang] ?? use.EN)[useKey];
  const message = dm({ handle, lang, category, angle, code, action, team });
  const spoken = readCopy({ handle, lang, code, action: spokenAction });
  const hold = priority === "HOLD" ? "\n- **Safety note:** Do not send until a fresh manual brand-safety review. Do not use the teacher/student angle for this channel." : "";
  const org = team ? "\n- **Route note:** This is an organization/broadcast channel; use its public partnerships or sponsorship contact, not a creator DM." : "";
  return `## ${rank}. ${handle}\n\n- **Followers:** ${followers}\n- **Language / recent category:** ${lang} / ${category}\n- **Priority:** ${priority}\n- **Public route:** [Twitch About / public business links](https://www.twitch.tv/${channelSlug}/about)\n- **Proposed audience code:** \`${code}\`\n- **Proposed tracked URL:** \`${SITE}/?ref=${channelSlug}\`\n- **Private creator pass:** \`CREATOR-${code.replace("NS-", "")}-{{ONE_TIME_SUFFIX}}\` — issue only after acceptance; not live yet.${hold}${org}\n\n**Personalized outreach message**\n\n> ${message}\n\n**On-stream read/adapt copy**\n\n> ${spoken}\n\n**If it is a giveaway, add this Twitch disclaimer**\n\n> ${promoDisclaimer(lang, handle)}\n`;
}).join("\n");

const document = `# NameSnap — top 100 Twitch creator outreach campaign\n\n**Research snapshot:** August 22, 2026  \n**Status:** Drafted, not sent. Creator passes, referral links, and commission tracking are proposed and must be implemented and tested before outreach.  \n**Product:** [NameSnap Web](${SITE}) — free for up to 16 contestants; web Premium supports unlimited contestants. No viewer account is needed, and contestant names and winner history stay in the host's browser.\n\n## What “largest” means\n\nThis list uses TwitchMetrics' current **most-followed Twitch channels**, ranked by total followers, pages 1–4, captured August 22, 2026. Social Blade's current top-100 followers list was used as a cross-check. TwitchMetrics updates continuously, so follower counts and recent categories are a dated snapshot. The source ranking includes official publisher/esports channels; those remain in rank order but are labeled **TEAM** and receive a partnerships pitch rather than a personal creator pitch.\n\nSources: [TwitchMetrics page 1](https://www.twitchmetrics.net/channels/follower?page=1), [page 2](https://www.twitchmetrics.net/channels/follower?page=2), [page 3](https://www.twitchmetrics.net/channels/follower?page=3), [page 4](https://www.twitchmetrics.net/channels/follower?page=4), and [Social Blade top 100](https://socialblade.com/twitch/lists/top/100/followers).\n\n## Commercial recommendation\n\nThe proposed launch offer is intentionally simple:\n\n- **Creator access:** one private, single-use code that permanently unlocks NameSnap Web Premium in the creator's production browser. If the creator changes machines, support can issue a replacement. Never put this code in public copy.\n- **Audience attribution:** a public creator link (\`?ref=creator\`) plus matching readable code. The code is for attribution, not the creator's free entitlement.\n- **Commission:** 40% of **net web revenue** attributable to that creator for 12 months after each referred customer's first purchase. “Net” means collected web revenue after refunds, chargebacks, taxes, discounts, and Stripe processing fees. Lifetime purchases pay once; monthly plans pay while the subscription remains paid, capped at 12 months per referred customer.\n- **Attribution window:** 30 days, last eligible creator click wins; manually entered creator code overrides the cookie. No self-referrals, code-directory posting, paid-search bidding on NameSnap terms, or misleading claims.\n- **Payouts:** monthly after a $50 balance, with required identity/tax paperwork and a downloadable statement. Unpaid balances roll forward.\n- **Pilot economics:** at current web pricing of $0.99/month or $6.99 lifetime, 40% is roughly $0.40 per paid month or $2.80 per lifetime sale before the net-revenue deductions above. That is unlikely to motivate the largest creators by itself. Treat the top-100 list as high-upside outreach; expect many to request a flat sponsorship fee. A second campaign aimed at mid-size education, family, party-game, and community creators will probably convert better.\n\nDo **not** add Stripe Connect for the pilot. NameSnap is selling its own product; creators are affiliates, not sellers in a marketplace. Keep the existing Stripe Payment Links, store the creator attribution against NameSnap's anonymous browser identity before redirecting to Stripe, create a commission ledger from verified Stripe webhooks, and pay the small number of accepted partners manually at first. Revisit connected-account onboarding only after the program has enough active earners that manual payouts are actually the bottleneck.\n\n## Minimal implementation before any message is sent\n\n1. Add a hashed, single-use creator-pass table and redemption endpoint that grants the existing anonymous browser entitlement.\n2. Add a creator-partner table with status, public code, commission rate, term, payout details status, and prohibited-channel flags.\n3. On \`?ref=slug\` or manual code entry, store a 30-day attribution record keyed to the existing one-way browser identity hash. Do not store contestant names.\n4. On verified Stripe checkout/subscription webhooks, join the paid identity to the active attribution and create immutable commission-ledger entries. Reverse entries for refunds and chargebacks.\n5. Build a monthly export showing gross collected, deductions, net web revenue, commission rate, earned commission, and payout status.\n6. Test code leakage, double redemption, last-click behavior, refunds, canceled subscriptions, duplicate webhooks, cleared browser storage, and creator replacement codes.\n7. Keep Stripe keys in Cloudflare secrets, use a restricted key where supported, and continue verifying webhook signatures.\n\n## Outreach rules\n\n- Do not bulk-send Twitch Whispers. Twitch's Terms prohibit unsolicited advertising/spam. Use only the creator's **publicly listed business email, Creator Profile, management form, or public business-social route**, and send one message plus one follow-up seven days later.\n- Verify the visible public route immediately before outreach. Do not buy, scrape, infer, or expose private contact details.\n- **P1:** first wave; clear giveaway/community/classroom crossover. **P2:** workable but less direct or more mature. **TEAM:** official channel; route to partnerships. **HOLD:** do not send until a fresh brand-safety review, and never use the school/student angle.\n- Do not ask children to purchase, recruit other children, or provide personal information. The free CTA may invite viewers to show the tool to a teacher, coach, club leader, family member, church/community group, or another adult who could use it. Under-18 viewers are told to ask a parent or guardian before purchasing.\n- The host—not NameSnap—must define eligibility, publish rules, verify entrants, award prizes, and comply with applicable promotion law. NameSnap only performs the random pick from the list the host supplies.\n\n## Required disclosure\n\nFree Premium access and commission are both material connections. Twitch says intentionally featured content given in exchange for value must use its Branded Content disclosure tool. The FTC says a live disclosure should be clear, hard to miss, included in the stream itself, and repeated periodically; a personalized code alone may not make the commission obvious. The copy below therefore says both “free access” and “commission.”\n\nReferences: [FTC Disclosures 101](https://www.ftc.gov/business-guidance/resources/disclosures-101-social-media-influencers), [FTC endorsement Q&A](https://www.ftc.gov/business-guidance/resources/ftcs-endorsement-guides-what-people-are-asking), [Twitch Branded Content Guidelines](https://help.twitch.tv/s/article/branded-content-policy), and [Twitch Terms of Service](https://www.twitch.tv/p/en/legal/terms-of-service/).\n\nFor giveaways, the streamer must also use Twitch's required promotion disclaimer, reproduced in each record below. Local law and the creator's own official rules may require additional language.\n\n## Ranked outreach records\n\n${sections}\n`;

fs.writeFileSync(OUTPUT, document);
console.log(`Wrote ${channels.length} outreach records to ${OUTPUT}`);
