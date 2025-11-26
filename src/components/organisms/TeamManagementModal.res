%%raw("import { t } from '@lingui/macro'")

open Lingui.Util
open Rating

type teamData = {
  id: int,
  name: string,
  playerIds: array<string>,
}

module TeamEditor = {
  @react.component
  let make = (
    ~team: teamData,
    ~players: array<Player.t<'a>>,
    ~onSave: teamData => unit,
    ~onCancel: unit => unit,
  ) => {
    let ts = Lingui.UtilString.t
    let (name, setName) = React.useState(() => team.name)
    let (selectedPlayerIds, setSelectedPlayerIds) = React.useState(() =>
      team.playerIds->Set.fromArray
    )

    let handleTogglePlayer = (playerId: string) => {
      setSelectedPlayerIds(prev => {
        let newSet = prev->Set.values->Array.fromIterator->Set.fromArray
        if prev->Set.has(playerId) {
          newSet->Set.delete(playerId)->ignore
        } else {
          newSet->Set.add(playerId)->ignore
        }
        newSet
      })
    }

    let handleSave = () => {
      onSave({
        id: team.id,
        name,
        playerIds: selectedPlayerIds->Set.values->Array.fromIterator,
      })
    }

    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] flex flex-col">
        // Header
        <div
          className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between flex-shrink-0">
          <div className="flex items-center gap-3">
            <Lucide.Users className="w-6 h-6 text-blue-600" />
            <h2 className="text-xl font-bold text-slate-800"> {t`Edit Team`} </h2>
          </div>
          <button
            onClick={_ => onCancel()}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            ariaLabel="Close">
            <Lucide.X className="w-5 h-5 text-slate-600" />
          </button>
        </div>
        // Content
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          // Team Name
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              {t`Team Name`}
            </label>
            <input
              type_="text"
              value={name}
              onChange={e => {
                let value = ReactEvent.Form.target(e)["value"]
                setName(_ => value)
              }}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder={ts`Enter team name`}
            />
          </div>
          // Players
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              {t`Team Members (${selectedPlayerIds->Set.size->Int.toString})`}
            </label>
            <div className="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto">
              {players
              ->Array.map(player => {
                let isSelected = selectedPlayerIds->Set.has(player.id)
                let buttonClass = isSelected
                  ? "flex items-center gap-2 p-2 rounded-lg border-2 transition-all text-left border-blue-500 bg-blue-50"
                  : "flex items-center gap-2 p-2 rounded-lg border-2 transition-all text-left border-slate-200 bg-white hover:border-slate-300"

                <button
                  key={player.id}
                  onClick={_ => handleTogglePlayer(player.id)}
                  className={buttonClass}>
                  <div className="w-8 h-8 rounded-full bg-slate-200 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-semibold text-slate-800 truncate">
                      {player.name->React.string}
                    </div>
                    <div className="text-xs text-slate-500">
                      {`#${player.intId->Int.toString}`->React.string}
                    </div>
                  </div>
                  {isSelected
                    ? <div
                        className="w-5 h-5 rounded-full bg-blue-600 flex items-center justify-center flex-shrink-0">
                        <svg
                          className="w-3 h-3 text-white"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor">
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="3"
                            d="M5 13l4 4L19 7"
                          />
                        </svg>
                      </div>
                    : React.null}
                </button>
              })
              ->React.array}
            </div>
          </div>
        </div>
        // Footer
        <div
          className="bg-slate-50 border-t border-slate-200 px-6 py-4 flex items-center justify-end gap-3 flex-shrink-0">
          <button
            onClick={_ => onCancel()}
            className="px-4 py-2 rounded-lg font-medium bg-white border border-slate-300 text-slate-700 hover:bg-slate-50 transition-colors">
            {t`Cancel`}
          </button>
          <button
            onClick={_ => handleSave()}
            disabled={name->String.trim == ""}
            className={name->String.trim == ""
              ? "px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-slate-300 text-slate-500 cursor-not-allowed"
              : "px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-blue-600 text-white hover:bg-blue-700"}>
            {t`Save Team`}
          </button>
        </div>
      </div>
    </div>
  }
}

@react.component
let make = (
  ~teams: array<teamData>,
  ~antiTeams: array<teamData>,
  ~players: array<Player.t<'a>>,
  ~onSave: (array<teamData>, array<teamData>) => unit,
  ~onClose: unit => unit,
) => {
  let ts = Lingui.UtilString.t
  let (localTeams, setLocalTeams) = React.useState(() => teams)
  let (localAntiTeams, setLocalAntiTeams) = React.useState(() => antiTeams)
  let (activeTab, setActiveTab) = React.useState(() => #teams) // #teams or #antiTeams
  let (editingTeam, setEditingTeam) = React.useState(() => None)
  let (isCreating, setIsCreating) = React.useState(() => false)

  let handleCreateTeam = () => {
    let newTeam: teamData = {
      id: Js.Date.now()->Float.toInt,
      name: activeTab == #teams ? ts`New Team` : ts`New Anti-Team`,
      playerIds: [],
    }
    setEditingTeam(_ => Some(newTeam))
    setIsCreating(_ => true)
  }

  let handleSaveTeam = (team: teamData) => {
    if isCreating {
      switch activeTab {
      | #teams => setLocalTeams(prev => prev->Array.concat([team]))
      | #antiTeams => setLocalAntiTeams(prev => prev->Array.concat([team]))
      }
      setIsCreating(_ => false)
    } else {
      switch activeTab {
      | #teams => setLocalTeams(prev => prev->Array.map(t => t.id == team.id ? team : t))
      | #antiTeams => setLocalAntiTeams(prev => prev->Array.map(t => t.id == team.id ? team : t))
      }
    }
    setEditingTeam(_ => None)
  }

  let handleDeleteTeam = (teamId: int) => {
    switch activeTab {
    | #teams => setLocalTeams(prev => prev->Array.filter(t => t.id != teamId))
    | #antiTeams => setLocalAntiTeams(prev => prev->Array.filter(t => t.id != teamId))
    }
  }

  let handleSave = () => {
    onSave(localTeams, localAntiTeams)
    onClose()
  }

  let currentTeams = activeTab == #teams ? localTeams : localAntiTeams

  switch editingTeam {
  | Some(team) =>
    <TeamEditor
      team
      players
      onSave={handleSaveTeam}
      onCancel={() => {
        setEditingTeam(_ => None)
        setIsCreating(_ => false)
      }}
    />
  | None =>
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] flex flex-col">
        // Header
        <div
          className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between flex-shrink-0">
          <div className="flex items-center gap-3">
            <Lucide.Users className="w-6 h-6 text-blue-600" />
            <div>
              <h2 className="text-xl font-bold text-slate-800"> {t`Team Management`} </h2>
              <p className="text-sm text-slate-600"> {t`Create and manage player teams`} </p>
            </div>
          </div>
          <button
            onClick={_ => onClose()}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            ariaLabel="Close">
            <Lucide.X className="w-5 h-5 text-slate-600" />
          </button>
        </div>
        // Tabs
        <div className="flex border-b border-slate-200 px-6">
          <button
            onClick={_ => setActiveTab(_ => #teams)}
            className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab ==
                #teams
                ? "border-blue-600 text-blue-600"
                : "border-transparent text-slate-500 hover:text-slate-700"}`}>
            {t`Teams`}
          </button>
          <button
            onClick={_ => setActiveTab(_ => #antiTeams)}
            className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab ==
                #antiTeams
                ? "border-blue-600 text-blue-600"
                : "border-transparent text-slate-500 hover:text-slate-700"}`}>
            {t`Anti-Teams`}
          </button>
        </div>
        // Teams List
        <div className="flex-1 overflow-y-auto p-6">
          {currentTeams->Array.length == 0
            ? <div className="text-center py-12">
                <Lucide.Users className="w-16 h-16 mx-auto mb-4 text-slate-300" />
                <p className="text-slate-600 font-medium mb-2">
                  {activeTab == #teams ? t`No teams yet` : t`No anti-teams yet`}
                </p>
                <p className="text-sm text-slate-500">
                  {activeTab == #teams
                    ? t`Create your first team to get started`
                    : t`Create your first anti-team to prevent players from pairing`}
                </p>
              </div>
            : <div className="space-y-3">
                {currentTeams
                ->Array.map(team => {
                  <div
                    key={team.id->Int.toString}
                    className="flex items-center gap-3 p-4 bg-slate-50 rounded-lg border border-slate-200">
                    <div className="flex-1 min-w-0">
                      <div className="font-semibold text-slate-800">
                        {team.name->React.string}
                      </div>
                      <div className="text-sm text-slate-600">
                        {`${team.playerIds
                          ->Array.length
                          ->Int.toString} player${team.playerIds->Array.length != 1
                            ? "s"
                            : ""}`->React.string}
                      </div>
                    </div>
                    <button
                      onClick={_ => setEditingTeam(_ => Some(team))}
                      className="p-2 hover:bg-slate-200 rounded-lg transition-colors"
                      title={ts`Edit team`}>
                      <Lucide.Edit2 className="w-4 h-4 text-slate-600" />
                    </button>
                    <button
                      onClick={_ => handleDeleteTeam(team.id)}
                      className="p-2 hover:bg-red-100 rounded-lg transition-colors"
                      title={ts`Delete team`}>
                      <Lucide.Trash2 className="w-4 h-4 text-red-600" />
                    </button>
                  </div>
                })
                ->React.array}
              </div>}
        </div>
        // Footer
        <div
          className="bg-slate-50 border-t border-slate-200 px-6 py-4 flex items-center justify-between flex-shrink-0">
          <button
            onClick={_ => handleCreateTeam()}
            className="px-4 py-2 rounded-lg font-medium bg-blue-600 text-white hover:bg-blue-700 transition-colors flex items-center gap-2">
            <Lucide.Plus className="w-4 h-4" />
            {activeTab == #teams ? t`Create Team` : t`Create Anti-Team`}
          </button>
          <button
            onClick={_ => handleSave()}
            className="px-6 py-2 rounded-lg font-medium bg-slate-800 text-white hover:bg-slate-900 transition-colors shadow-md">
            {t`Save & Close`}
          </button>
        </div>
      </div>
    </div>
  }
}
