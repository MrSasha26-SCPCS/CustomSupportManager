# CustomSupportManager
SCP: CS plugin (RP)

Плагин, с помощью которого можно добавлять свои собственные отряды и настраивать их.

**Установка:** как обычно (файлы с расширением `.lua` скопировать в папку `Plugins`).

**Настройка:** 
1) Создайте файл с названием `groups.json` в папке с исполняемым файлом сервера (просто в контейнер);
2) Воспользуйтесь примером, чтобы создать свой кастомный отряд:
```
{
    "Epsilon11" : {
        "single" : ["MTFCommander"],
        "others" : ["MTFSniper", "MTFLieutenant", "MTFCadet"],
        "haveEquipment" : ["MTFLieutenant"],
        "transport" : "helicopter",
        "isAutoSpawning" : false,
        "team" : "MTF",
        "name" : "<color=#3333FF>МОГ Epsilon-11</color>",
        "acesMessageWithSCP" : "MtfUnit Epsilon 11 HasEntered AllRemaining AwaitingRecontainment {scpCount} ScpSubject",
        "acesMessageNoSCP" : "MtfUnit Epsilon 11 HasEntered AllRemaining NoSCPsLeft"
    }
}
```
`single` - список ролей, которые должны быть единственными в отряде (от главного к менее главному);
`others` - список других ролей (от главных (меньше) к менее главным (больше));
`haveEquipment` - список ролей, которые получают предметы для контейма SCP (должны быть установлены плагины на мешок и клетку);
`transport` - транспорт, на котором прибывает группа (`helicopter`, `car` или `nil`);
`isAutoSpawning` - спавнится ли эта группа автоматически;
`team` - команда;
`name` - название, которое будет отображаться в админ панели и интеркоме (если установлен плагин);
`acesMessageWithSCP` - оповещение, которое будет проигрываться при наличии SCP;
`acesMessageNoSCP` - оповещение, которое будет проигрываться, если SCP отсутствуют.
