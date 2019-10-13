----------------------------------------------------------
----ITEM
----------------------------------------------------------
---@class ITEM
---@field public dwID number
---@field public szName string
---@field public nLevel number
---@field public nStrengthLevel number
---@field public nGenre number
---@field public nSub number
---@field public nDetail number
---@field public nBindType number
---@field public bCanTrade boolean
---@field public bCanDestroy boolean
---@field public dwTabType number
---@field public dwIndex number
---@field public nQuality number
---@field public nCurrentDurability number
---@field public nStackNum number
---@field public nMaxStackNum number
---@field public nMaxDurability number
---@field public nBookID number
---@field public bBind boolean
---@field public bCanStack boolean
---@field public bCanConsume boolean
---@field public nVersion number
---@field public dwPermanentEnchantID number
---@field public dwTemporaryEnchantID number
---@field public nMaxExistAmount number
---@field public nMaxExistTime number
---@field public nUiId number
---@field public dwSetID number

---@type ITEM
local ITEM = {}

---IsRepairable
---@return boolean
function ITEM.IsRepairable() end

---GetRequireAttrib
---@return table
function ITEM.GetRequireAttrib() end

---GetLeftExistTime
---@return number
function ITEM.GetLeftExistTime() end

---GetMagicAttrib
---@return table
function ITEM.GetMagicAttrib() end

---GetMountIndex
---@return boolean
function ITEM.GetMountIndex() end

---GetBaseAttrib
---@return table
function ITEM.GetBaseAttrib() end

---GetMagicAttribByStrengthLevel
---@param nStrengthLevel number
---@return table
function ITEM.GetMagicAttribByStrengthLevel(nStrengthLevel) end

---GetSlotCount
---@return number
function ITEM.GetSlotCount() end

---GetMountDiamondEnchantID
---@param nSlotIndex number
---@return number
function ITEM.GetMountDiamondEnchantID(nSlotIndex) end

---GetSlotAttrib
---@param nSlotIndex number
---@param nDiamondLevel number
---@return table
function ITEM.GetSlotAttrib(nSlotIndex, nDiamondLevel) end

---CanMountColorDiamond
---@return boolean
function ITEM.CanMountColorDiamond() end

---GetMountFEAEnchantID
---@return number
function ITEM.GetMountFEAEnchantID() end

---GetTemporaryEnchantLeftSeconds
---@return number
function ITEM.GetTemporaryEnchantLeftSeconds() end

----------------------------------------------------------
----ITEMINFO
----------------------------------------------------------
---@class ITEMINFO
---@field public dwID number
---@field public nUiId number
---@field public szName string
---@field public nLevel number
---@field public nGenre number
---@field public nSub number
---@field public nDetail number
---@field public nExistType number
---@field public nBindType number
---@field public nQuality number
---@field public nMaxExistAmount number
---@field public nMaxStrengthLevel number
---@field public nMaxExistTime number
---@field public nRecommendID number
---@field public dwCoolDownID number
---@field public dwSetID number

---@type ITEMINFO
local ITEMINFO = {}

---GetRequireAttrib
---@return table
function ITEMINFO.GetRequireAttrib() end

---GetBaseAttrib
---@return table
function ITEMINFO.GetBaseAttrib() end

---GetMagicAttribIndexList
---@return table
function ITEMINFO.GetMagicAttribIndexList() end

---GetCoolDown
---@return number
function ITEMINFO.GetCoolDown() end

----------------------------------------------------------
----DOODAD
----------------------------------------------------------
---@class DOODAD
---@field public dwID number
---@field public dwTemplateID number
---@field public szName string
---@field public nKind number
---@field public nX number
---@field public nY number
---@field public nZ number

---@type DOODAD
local DOODAD = {}

---GetScene
---@return number
function DOODAD.GetScene() end

---DistributeItem
---@param dwItemID number
---@param dwDstPlayerID number
---@return void
function DOODAD.DistributeItem(dwItemID, dwDstPlayerID) end

---CanLoot
---@param dwPlayerID number
---@return boolean
function DOODAD.CanLoot(dwPlayerID) end

---CanDialog
---@param player PLAYER
---@return boolean
function DOODAD.CanDialog(player) end

---HaveQuest
---@param dwPlayerID number
---@return boolean
function DOODAD.HaveQuest(dwPlayerID) end

---GetAbsoluteCoordinate
---@return number, number, number
function DOODAD.GetAbsoluteCoordinate() end

---IsSelectable
---@return boolean
function DOODAD.IsSelectable() end

---GetLootItem
---@param dwLootIndex number
---@param KObjData userdata
---@return ITEM, boolean, boolean
function DOODAD.GetLootItem(dwLootIndex, KObjData) end

---GetLootMoney
---@return number
function DOODAD.GetLootMoney() end

---GetLooterList
---@return table
function DOODAD.GetLooterList() end

---CanSit
---@return boolean
function DOODAD.CanSit() end

---GetRecipeID
---@return number
function DOODAD.GetRecipeID() end

----------------------------------------------------------
----SCENE
----------------------------------------------------------
---@class SCENE
---@field public dwID number
---@field public nType number
---@field public szName string
---@field public bCanTongWar boolean
---@field public bCanPK boolean
---@field public bCanDuel boolean
---@field public szDisplayName string
---@field public dwMapID number
---@field public nCopyIndex number
---@field public bReviveInSitu boolean
---@field public nInFightPlayerCount number
---@field public bCampType boolean
---@field public bIsArenaMap boolean

---@type SCENE
local SCENE = {}

---TimeLimitationBindItemGetLeftTime
---@param dwItemID number
---@return number
function SCENE.TimeLimitationBindItemGetLeftTime(dwItemID) end

----------------------------------------------------------
----NPC
----------------------------------------------------------
---@class NPC
---@field public dwID number
---@field public nX number
---@field public nY number
---@field public nZ number
---@field public nFaceDirection number
---@field public szName string
---@field public szTitle string
---@field public dwForceID number
---@field public nLevel number
---@field public dwTemplateID number
---@field public dwModelID number
---@field public nTouchRange number
---@field public bDialogFlag boolean
---@field public nGender number
---@field public nCurrentLife number
---@field public nMaxLife number
---@field public nCurrentMana number
---@field public nMaxMana number
---@field public nMoveState number
---@field public dwEmployer number
---@field public bFightState boolean
---@field public nCurrentRage number
---@field public nMaxRage number
---@field public nCurrentEnergy number
---@field public nMaxEnergy number
---@field public dwDropTargetPlayerID number

---@type NPC
local NPC = {}

---GetScene
---@return number
function NPC.GetScene() end

---GetBuffCount
---@return number
function NPC.GetBuffCount() end

---GetBuff
---@param nIndex number
---@return number
function NPC.GetBuff(nIndex) end

---GetTarget
---@return number, number
function NPC.GetTarget() end

---GetSkillPrepareState
---@return boolean, number, number, number
function NPC.GetSkillPrepareState() end

---CanDialog
---@param player PLAYER
---@return boolean
function NPC.CanDialog(player) end

---GetMapID
---@return number
function NPC.GetMapID() end

---CanSeeName
---@return boolean
function NPC.CanSeeName() end

---GetAbsoluteCoordinate
---@return number, number, number
function NPC.GetAbsoluteCoordinate() end

---CanSeeLifeBar
---@return boolean
function NPC.CanSeeLifeBar() end

---IsSelectable
---@return boolean
function NPC.IsSelectable() end

---SetTarget
---@param eTargetType number
---@param dwTargetID number
function NPC.SetTarget(eTargetType, dwTargetID) end

---GetNpcQuest
---@return table
function NPC.GetNpcQuest() end

----------------------------------------------------------
----PLAYER
----------------------------------------------------------
---@class PLAYER
---@field public dwID number
---@field public nX number
---@field public nY number
---@field public nZ number
---@field public nFaceDirection number
---@field public szName string
---@field public szTitle string
---@field public dwForceID number
---@field public nLevel number
---@field public nExperience number
---@field public nOnPracticeRoom number
---@field public nCurrentStamina number
---@field public nMaxStamina number
---@field public nCurrentThew number
---@field public nMaxThew number
---@field public nBattleFieldSide number
---@field public dwSchoolID number
---@field public nCurrentTrainValue number
---@field public nMaxTrainValue number
---@field public nUsedTrainValue number
---@field public nDirectionXY number
---@field public nDirectionXY number
---@field public nMaxTrainValue number
---@field public nCurrentLife number
---@field public nMaxLife number
---@field public nMaxLifeBase number
---@field public nCurrentMana number
---@field public nMaxMana number
---@field public nMaxManaBase number
---@field public nCurrentEnergy number
---@field public nMaxEnergy number
---@field public nEnergyReplenish number
---@field public bCanUseBigSword number
---@field public nAccumulateValue number
---@field public nCamp number
---@field public nCampFlag number
---@field public bOnHorse boolean
---@field public nMoveState number
---@field public dwTongID number
---@field public nGender number
---@field public nCurrentRage number
---@field public nMaxRage number
---@field public dwEmployer number
---@field public nCurrentPrestige number
---@field public bFightState boolean
---@field public nRunSpeed number
---@field public nRunSpeedBase number
---@field public dwTeamID number
---@field public nRoleType number
---@field public nContribution number
---@field public nCoin number
---@field public nJustice number
---@field public nExamPrint number
---@field public nArenaAward number
---@field public nActivityAward number
---@field public bHideHat boolean
---@field public bRedName boolean
---@field public dwKillCount number
---@field public nRankPoint number
---@field public nTitle number
---@field public dwPetID number
---@field public nTitle number
---@field public nCurrentSunEnergy number
---@field public nSunPowerValue number
---@field public nMaxSunEnergy number
---@field public nCurrentMoonEnergy number
---@field public nMoonPowerValue number
---@field public dwMiniAvatarID number
---@field public bCampFlag number
---@field public nSprintPower number
---@field public nSprintPowerMax number
---@field public nSprintPowerRevive number
---@field public nHorseSprintPower number
---@field public nHorseSprintPowerMax number
---@field public nHorseSprintPowerReviv number
---@field public bSprintFlag number

---@type PLAYER
local PLAYER = {}

---CancelBuff
---@param nIndex number
---@return boolean
function PLAYER.CancelBuff(nIndex) end

---GetGlobalID
---@return number
function PLAYER.GetGlobalID() end

---GetItem
---@param dwBoxIndex number
---@param dwX number
---@return ITEM
function PLAYER.GetItem(dwBoxIndex, dwX) end

---GetScene
---@return SCENE
function PLAYER.GetScene() end

---GetRecipe
---@param dwProfessionID number
---@return table
function PLAYER.GetRecipe(dwProfessionID) end

---GetBuffCount
---@return number
function PLAYER.GetBuffCount() end

---GetBuff
---@param nIndex number
---@return table
function PLAYER.GetBuff(nIndex) end

---GetProfession
---@return table
function PLAYER.GetProfession() end

---GetPet
---@return NPC
function PLAYER.GetPet() end

---GetItemAmountInAllPackages
---@param dwTabType number
---@param dwIndex number
---@return number
function PLAYER.GetItemAmountInAllPackages(dwTabType, dwIndex) end

---Talk
---@param nTalkRange number
---@param szReceiver string
---@param tData table
---@return void
function PLAYER.Talk(nTalkRange, szReceiver, tData) end

---CastProfessionSkill
---@param dwCraft number
---@param dwRecipeID number
---@param eTargetType number
---@param dwTargetID number
---@overload fun(dwCraft, dwRecipeID)
---@overload fun(dwCraftID, dwBookID, dwBookSubID)
---@return number
function PLAYER.CastProfessionSkill(dwCraft, dwRecipeID, eTargetType, dwTargetID) end

---StopCurrentAction
---@return boolean
function PLAYER.StopCurrentAction() end

---GetTarget
---@return number, number
function PLAYER.GetTarget() end

---IsInParty
---@return boolean
function PLAYER.IsInParty() end

---GetSkillLevel
---@param dwSkillID number
---@return number
function PLAYER.GetSkillLevel(dwSkillID) end

---GetBoxSize
---@param dwBoxIndex number
---@return number
function PLAYER.GetBoxSize(dwBoxIndex) end

---GetKungfuMount
---@return userdata
function PLAYER.GetKungfuMount() end

---IsPlayerInMyParty
---@param dwPlayerID number
---@return boolean
function PLAYER.IsPlayerInMyParty(dwPlayerID) end

---GetTalkData
---@return table
function PLAYER.GetTalkData() end

---GetSkillCDProgress
---@param dwSkillID number
---@param dwSkillLevel number
---@return boolean, number, number
function PLAYER.GetSkillCDProgress(dwSkillID, dwSkillLevel) end

---GetItemAmount
---@param dwTabType number
---@param dwIndex number
---@param dwBookID number
---@param dwBookSubID number
---@overload fun(dwTabType, dwIndex)
---@return number
function PLAYER.GetItemAmount(dwTabType, dwIndex, dwBookID, dwBookSubID) end

---GetProfessionLevel
---@param dwProfessionID number
---@return number, number
function PLAYER.GetProfessionLevel(dwProfessionID) end

---GetOTActionState
---@return number
function PLAYER.GetOTActionState() end

---GetQuestTraceInfo
---@param dwQuestID number
---@return table
function PLAYER.GetQuestTraceInfo(dwQuestID) end

---GetSkillPrepareState
---@return boolean, number, number, number
function PLAYER.GetSkillPrepareState() end

---GetMoney
---@return number
function PLAYER.GetMoney() end

---GetSkillRecipeKey
---@param dwSkillID number
---@param dwSkillLevel number
---@return table
function PLAYER.GetSkillRecipeKey(dwSkillID, dwSkillLevel) end

---GetRepresentID
---@return number
function PLAYER.GetRepresentID() end

---GetQuestPhase
---@param dwQuestID number
---@return number
function PLAYER.GetQuestPhase(dwQuestID) end

---GetQuestID
---@param nQuestIndex number
---@return number
function PLAYER.GetQuestID(nQuestIndex) end

---GetReputeLevel
---@param dwForceID number
---@return number
function PLAYER.GetReputeLevel(dwForceID) end

---GetQuestTree
---@return table
function PLAYER.GetQuestTree() end

---GetQuestExpAttenuation
---@param dwQuestID number
---@return number, number, number
function PLAYER.GetQuestExpAttenuation(dwQuestID) end

---CanDialog
---@param player PLAYER
---@return boolean
function PLAYER.CanDialog(player) end

---GetQuestState
---@param dwQuestID number
---@return number
function PLAYER.GetQuestState(dwQuestID) end

---GetBookSegmentList
---@param dwBookID number
---@return table
function PLAYER.GetBookSegmentList(dwBookID) end

---GetItemCDProgress
---@return boolean, number, number, boolean
function PLAYER.GetItemCDProgress() end

---GetMapID
---@return number
function PLAYER.GetMapID() end

---GetQuestDiffcultyLevel
---@param dwQuestID number
---@return number
function PLAYER.GetQuestDiffcultyLevel(dwQuestID) end

---GetBookList
---@return table
function PLAYER.GetBookList() end

---IsRecipeLearned
---@param dwCraftID number
---@param dwRecipeID number
---@return boolean
function PLAYER.IsRecipeLearned(dwCraftID, dwRecipeID) end

---GetProfessionMaxLevel
---@param dwProfessionID number
---@return number
function PLAYER.GetProfessionMaxLevel(dwProfessionID) end

---GetProfessionProficiency
---@param dwProfessionID number
---@return number
function PLAYER.GetProfessionProficiency(dwProfessionID) end

---GetSkillRecipeList
---@param dwSkillID number
---@param dwSkillLevel number
---@return table
function PLAYER.GetSkillRecipeList(dwSkillID, dwSkillLevel) end

---OpenVenation
---@param nVenationID number
---@return boolean
function PLAYER.OpenVenation(nVenationID) end

---IsBookMemorized
---@param dwBookID number
---@param dwBookSubID number
---@return boolean
---@public
function PLAYER.IsBookMemorized(dwBookID, dwBookSubID) end

---GetBoxFreeRoomSize
---@param dwBoxIndex number
---@return number
---@public
function PLAYER.GetBoxFreeRoomSize(dwBoxIndex) end

---GetBankPackageCount
---@return number
function PLAYER.GetBankPackageCount() end

---GetProfessionBranch
---@param dwProfessionID number
---@return number
---@public
function PLAYER.GetProfessionBranch(dwProfessionID) end

---GetAbsoluteCoordinate
---@return number, number, number
function PLAYER.GetAbsoluteCoordinate() end

---IsAchievementAcquired
---@param nAchievementID number
---@return boolean
function PLAYER.IsAchievementAcquired(nAchievementID) end

---IsInRaid
---@return boolean
function PLAYER.IsInRaid() end

---GetAllSkillList
---@return table
function PLAYER.GetAllSkillList() end

---GetReputation
---@param dwForceID number
---@return number
function PLAYER.GetReputation(dwForceID) end

---Jump
---@param bStandJump boolean
---@param nDirectionXY number
---@return void
function PLAYER.Jump(bStandJump, nDirectionXY) end

---WindowSelect
---@param dwIndex number
---@param bySelect number
---@return void
function PLAYER.WindowSelect(dwIndex, bySelect) end

---GetTalkLinkItem
---@param dwItemID number
---@return ITEM
function PLAYER.GetTalkLinkItem(dwItemID) end

---CanAcceptQuest
---@param dwQuestID number
---@param eTargetType number
---@param dwTargetID number
---@overload fun(dwQuestID)
---@overload fun(dwQuestID, dwTemplateID)
---@return number
function PLAYER.CanAcceptQuest(dwQuestID, eTargetType, dwTargetID) end

---OpenTalent
---@param nTalentID number
---@param nTalentLevel number
---@return boolean
function PLAYER.OpenTalent(nTalentID, nTalentLevel) end

---SatisfyRequire
---@param nAttributeID number
---@param nValue1 number
---@param nValue2 number
---@overload fun(nAttributeID, nValue1)
---@return boolean
function PLAYER.SatisfyRequire(nAttributeID, nValue1, nValue2) end

---IsDesignationPrefixAcquired
---@param nPrefix number
---@return boolean
function PLAYER.IsDesignationPrefixAcquired(nPrefix) end

---IsDesignationPostfixAcquired
---@param nPostfix number
---@return boolean
function PLAYER.IsDesignationPostfixAcquired(nPostfix) end

---GetProfessionAdjustLevel
---@param dwProfessionID number
---@return number
function PLAYER.GetProfessionAdjustLevel(dwProfessionID) end

---IsPartyLeader
---@return boolean
function PLAYER.IsPartyLeader() end

---IsPartyFull
---@return boolean
function PLAYER.IsPartyFull() end

---CanApplyDuel
---@param dwTargetID number
---@return boolean
function PLAYER.CanApplyDuel(dwTargetID) end

---CanAddFoe
---@return boolean
function PLAYER.CanAddFoe() end

---GetEquipPos
---@param dwBoxIndex number
---@param dwX number
---@return number
function PLAYER.GetEquipPos(dwBoxIndex, dwX) end

---GetMaxExamPrint
---@return number
function PLAYER.GetMaxExamPrint() end

---GetExamPrintRemainSpace
---@return number
function PLAYER.GetExamPrintRemainSpace() end

---IsProfessionLearnedByCraftID
---@param dwCraftID number
---@return boolean
function PLAYER.IsProfessionLearnedByCraftID(dwCraftID) end

---GetEquipIDArray
---@param nID number
---@return number
function PLAYER.GetEquipIDArray(nID) end

---ExchangeItem
---@param dwSrcBox number
---@param dwSrcX number
---@param dwDestBox number
---@param dwDestX number
---@param dwAmount number
---@overload fun(dwSrcBox, dwSrcX, dwDestBox, dwDestX)
---@return boolean
function PLAYER.ExchangeItem(dwSrcBox, dwSrcX, dwDestBox, dwDestX, dwAmount) end

---GetMapVisitFlag
---@param dwMapID number
---@return number
function PLAYER.GetMapVisitFlag(dwMapID) end

---GetFellowshipGroupInfo
---@return table
function PLAYER.GetFellowshipGroupInfo() end

---GetFellowshipInfo
---@param dwGroupID number
---@return table
function PLAYER.GetFellowshipInfo(dwGroupID) end

---GetKungfuList
---@param dwSchoolID number
---@return table
function PLAYER.GetKungfuList(dwSchoolID) end

---GetSkillList
---@param dwKungfuID number
---@return table
function PLAYER.GetSkillList(dwKungfuID) end

---IsPartyMemberInSameScene
---@param dwID number
---@return boolean
function PLAYER.IsPartyMemberInSameScene(dwID) end

---GetItemPos
---@param dwItemID number
---@overload fun(dwTabType, dwIndex)
---@overload fun(nVersion, dwTabType, dwIndex)
---@return number, number
function PLAYER.GetItemPos(dwItemID) end

---CanBreakEquip
---@param dwBoxIndex number
---@param dwX number
---@return boolean
function PLAYER.CanBreakEquip(dwBoxIndex, dwX) end

---ActiveSkillRecipe
---@param dwRecipeID number
---@param dwRecipeLevel number
---@return boolean
function PLAYER.ActiveSkillRecipe(dwRecipeID, dwRecipeLevel) end

---DeactiveSKillRecipe
---@param dwRecipeID number
---@param dwRecipeLevel number
---@return boolean
function PLAYER.DeactiveSKillRecipe(dwRecipeID, dwRecipeLevel) end

---GetCDInterval
---@param dwCooldownID number
---@return number
function PLAYER.GetCDInterval(dwCooldownID) end

---GetTotalEquipScore
---@return number
function PLAYER.GetTotalEquipScore() end

---GetBaseEquipScore
---@return number
function PLAYER.GetBaseEquipScore() end

---GetStrengthEquipScore
---@return number
function PLAYER.GetStrengthEquipScore() end

---GetMountsEquipScore
---@return number
function PLAYER.GetMountsEquipScore() end

---GetFoeInfo
---@return table
function PLAYER.GetFoeInfo() end

---SetFellowshipRemark
---@param dwAlliedPlayerID number
---@param szRemark string
---@return boolean
function PLAYER.SetFellowshipRemark(dwAlliedPlayerID, szRemark) end

---GetCDLeft
---@param dwCoolDownID number
---@return number
function PLAYER.GetCDLeft(dwCoolDownID) end

----------------------------------------------------------
---- TEAMCLIENT
----------------------------------------------------------
---@class TEAMCLIENT
---@field public dwTeamID number
---@field public bSystem boolean
---@field public bTeamLeader boolean
---@field public nLootMode number
---@field public nRollQuality number
---@field public nCamp number
---@field public dwDistributeMan number
---@field public dwFormationLeader number
---@field public nInComeMoney number
---@field public nGroupNum number

---@type TEAMCLIENT
local TEAMCLIENT = {}

---ChangeMemberGroup
---@param dwTargetMemberID number
---@param nTargetGroup number
---@return void
function TEAMCLIENT.ChangeMemberGroup(dwTargetMemberID, nTargetGroup) end

---SetTeamFormationLeader
---@param dwNewFormationLeader number
---@param nGroupIndex number
---@overload fun(dwTargetMemberID)
---@return void
function TEAMCLIENT.SetTeamFormationLeader(dwNewFormationLeader, nGroupIndex) end

---TeamNotifySignpost
---@param nX number
---@param nY number
---@return void
function TEAMCLIENT.TeamNotifySignpost(nX, nY) end

---SetTeamRollQuality
---@param nQuality number
---@return void
function TEAMCLIENT.SetTeamRollQuality(nQuality) end

---GetMemberInfo
---@param dwMemberID number
---@return table
function TEAMCLIENT.GetMemberInfo(dwMemberID) end

---GetGroupInfo
---@param nTeamGroup number
---@return table
function TEAMCLIENT.GetGroupInfo(nTeamGroup) end

---GetMemberGroupIndex
---@param dwMemberID number
---@return number
function TEAMCLIENT.GetMemberGroupIndex(dwMemberID) end

---GetTeamMark
---@return table
function TEAMCLIENT.GetTeamMark() end

---GetMarkIndex
---@param dwMemberID number
---@return number
function TEAMCLIENT.GetMarkIndex(dwID) end

---SetTeamMark
---@param nMarkType number
---@param dwTargetID number
---@return void
function TEAMCLIENT.SetTeamMark(nMarkType, dwTargetID) end

---GetAuthorityInfo
---@param dwAuthority number
---@return void
function TEAMCLIENT.GetAuthorityInfo(dwAuthority) end

---SetAuthorityInfo
---@param dwAuthority number
---@param dwTargetID number
---@return void
function TEAMCLIENT.SetAuthorityInfo(dwAuthority, dwTargetID) end

---IsPlayerInTeam
---@param dwPlayerID number
---@return boolean
function TEAMCLIENT.IsPlayerInTeam(dwPlayerID) end

---GetClientTeamMemberName
---@param dwMemberID number
---@return void
function TEAMCLIENT.GetClientTeamMemberName(dwMemberID) end

---SetTeamLootMode
---@param nLootMode number
---@return void
function TEAMCLIENT.SetTeamLootMode(nLootMode) end

---GetTeamSize
---@return number
function TEAMCLIENT.GetTeamSize() end

---GetTeamMemberList
---@return table
function TEAMCLIENT.GetTeamMemberList() end

----------------------------------------------------------
---- TONGCLIENT
----------------------------------------------------------
---@class TONGCLIENT
---@field public dwMaster number
---@field public nTotalWageRate number
---@field public nLevel number
---@field public nDevelopmentPoint number
---@field public nMaxMemberCount number
---@field public bCanModifyGroupWage boolean
---@field public nCamp number
---@field public szTongName string
---@field public szAnnouncement string
---@field public szOnlineMessage string
---@field public szIntroduction string
---@field public szRules string
---@field public nState number

---@type TONGCLIENT
local TONGCLIENT = {}

---ApplyGetTongName
---@param dwTongID number
---@return string
function TONGCLIENT.ApplyGetTongName(dwTongID) end

---ChangeMemberGroup
---@param dwMemberID number
---@param nDstGroup number
---@param dwDstMemberID number
---@overload fun(dwMemberID, nDstGroup)
---@return void
function TONGCLIENT.ChangeMemberGroup(dwMemberID, nDstGroup, dwDstMemberID) end

---ApplyRepertoryPage
---@param nPageIndex number
---@return void
function TONGCLIENT.ApplyRepertoryPage(nPageIndex) end

---ApplyOpenRepertory
---@param dwNpcID number
---@return void
function TONGCLIENT.ApplyOpenRepertory(dwNpcID) end

---GetMemberInfo
---@param dwPlayerID number
---@return void
function TONGCLIENT.GetMemberInfo(dwPlayerID) end

---GetGroupInfo
---@param dwGroupID number
---@return table
function TONGCLIENT.GetGroupInfo(dwGroupID) end

---GetMemberCount
---@return number
function TONGCLIENT.GetMemberCount() end

---GetMemberList
---@param bOffLine boolean
---@param szSort string
---@param bRise boolean
---@param nGroupFilter number
---@param nSchoolFilter number
function TONGCLIENT.GetMemberList(bOffLine, szSort, bRise, nGroupFilter, nSchoolFilter) end

---CheckBaseOperationGroup
---@param nGroup number
---@param nOperationIndex number
---@return boolean
function TONGCLIENT.CheckBaseOperationGroup(nGroup, nOperationIndex) end

---ApplyTongInfo
---@return void
function TONGCLIENT.ApplyTongInfo() end

---ApplyTongRoster
---@return void
function TONGCLIENT.ApplyTongRoster() end

---GetRepertoryItem
---@param nPageIndex number
---@param nPagePos number
---@return ITEM
function TONGCLIENT.GetRepertoryItem(nPageIndex, nPagePos) end

----------------------------------------------------------
---- MAILINFO
----------------------------------------------------------
---@class MAILINFO
---@field public dwMailID number
---@field public szSenderName string
---@field public szTitle string
---@field public bReadFlag boolean
---@field public bMoneyFlag boolean
---@field public bItemFlag boolean
---@field public bPayFlag boolean
---@field public bGotContentFlag boolean
---@field public nMoney number
---@field public nAllItemPrice number

---@type MAILINFO
local MAILINFO = {}

---RequestContent
---@param dwNpcID number
---@return void
function MAILINFO.RequestContent(dwNpcID) end

---GetItem
---@param nIndex number
---@return ITEM
function MAILINFO.GetItem(nIndex) end

---TakeItem
---@param nIndex number
---@return void
function MAILINFO.TakeItem(nIndex) end

---GetType
---@return number
function MAILINFO.GetType() end

---GetText
---@return string
function MAILINFO.GetText() end

---TakeMoney
---@return void
function MAILINFO.TakeMoney() end

---GetLeftTime
---@return number
function MAILINFO.GetLeftTime() end

---Read
---@return void
function MAILINFO.Read() end

----------------------------------------------------------
---- MAILCLIENT
----------------------------------------------------------
---@class MAILCLIENT
local MAILCLIENT = {}

---GetMailInfo
---@param dwMailID number
---@return MAILINFO
function MAILCLIENT.GetMailInfo(dwMailID) end

---GetMailList
---@return table @返回一个下标从1开始的table，每一项包含以下内容: MailID:  邮件Id SenderName: 发送者名字 Title:  主题 LeftSeconds: 邮件剩余时间 UnReadFlag: 是否已读 MoneyFlag: 是否有金钱 TextFlag: 是否有正文 ItemFlag: 是否有附件 SystemFlag: 是否是系统邮件
function MAILCLIENT.GetMailList() end

---DeleteMail 删除邮件
---@param dwMailID number
---@return void
function MAILCLIENT.DeleteMail(dwMailID) end

---CountMail
---@return number, number
function MAILCLIENT.CountMail() end

----------------------------------------------------------
----Global API
----------------------------------------------------------
---GetClientPlayer
---@return PLAYER
function GetClientPlayer() end



