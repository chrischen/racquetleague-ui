%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

type tagType = [#comp | #recreational | #drill | #dupr | #level | #other]
type tagCategory = [#"type" | #level]

let getTagType = tag =>
  switch tag {
  | "comp" => #comp
  | "rec" => #recreational
  | "drill" => #drill
  | "dupr" => #dupr
  | "all level" | "3.0+" | "3.5+" | "4.0+" | "4.5+" | "5.0+" => #level
  | _ => #other
  }

let getTagCategory = tag =>
  switch tag {
  | "comp" | "rec" | "drill" | "dupr" => #"type"
  | "all level" | "3.0+" | "3.5+" | "4.0+" | "4.5+" | "5.0+" => #level
  | _ => #"type"
  }

// Hook for mobile detection
let useMobileDetection = () => {
  let (isMobile, setIsMobile) = React.useState(() => false)

  React.useEffect0(() => {
    let checkIsMobile = () => {
      setIsMobile(_ => %raw("typeof window !== 'undefined' && window.innerWidth < 768"))
    }
    checkIsMobile()

    let handleResize = () => checkIsMobile()
    %raw("window.addEventListener")("resize", handleResize)->ignore

    Some(() => %raw("window.removeEventListener")("resize", handleResize)->ignore)
  })

  isMobile
}

// Single tag input component
@react.component
let make = (
  ~tag: string,
  ~isSelected: bool,
  ~onToggle: unit => unit,
  ~category: tagCategory=#"type",
) => {
  let td = Lingui.UtilString.dynamic
  let isMobile = useMobileDetection()

  let buttonContent =
    <button
      type_="button"
      onClick={_ => onToggle()}
      className={Util.cx([
        "inline-flex items-center rounded-md px-3 py-2 text-sm font-semibold shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 cursor-help",
        isSelected
          ? "bg-indigo-600 text-white hover:bg-indigo-500 focus-visible:outline-indigo-600"
          : "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:outline-indigo-600",
      ])}>
      {td(tag)->React.string}
    </button>

  isMobile
    ? <Radix.Popover.Root>
        <Radix.Popover.Trigger asChild=true> {buttonContent} </Radix.Popover.Trigger>
        <Radix.Popover.Content
          side=#top
          className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
          {EventTag.getTagTooltip(tag)->React.string}
        </Radix.Popover.Content>
      </Radix.Popover.Root>
    : <Radix.Tooltip.Root delayDuration=200.>
        <Radix.Tooltip.Trigger asChild=true> {buttonContent} </Radix.Tooltip.Trigger>
        <Radix.Tooltip.Content
          side=#top
          className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
          {EventTag.getTagTooltip(tag)->React.string}
        </Radix.Tooltip.Content>
      </Radix.Tooltip.Root>
}

// Tag selection logic helper functions
module TagLogic = {
  let getMainTypeTags = () => ["rec", "comp"] // Both "rec" and "comp" are main tags
  let getSubTags = (state: [#"rec" | #comp]) =>
    switch state {
    | #"rec" => ["drill"] // When rec selected, show drill
    | #comp => ["drill", "dupr"] // When comp selected, show both options
    }
  let getAllSubTags = () => {
    // Get all possible sub-tags by manually combining them
    ["drill", "dupr"]
  }
  let getLevelTags = () => ["all level", "3.0+", "3.5+", "4.0+", "4.5+", "5.0+"]

  // Get current event type state based on selected tags
  let getEventTypeState = (selectedTags: array<string>) => {
    if selectedTags->Array.includes("comp") {
      #comp
    } else {
      #"rec" // Default state when comp is not selected
    }
  }

  // Check if a tag should be highlighted
  let isTagHighlighted = (tag: string, selectedTags: array<string>) => {
    switch tag {
    | "rec" => !(selectedTags->Array.includes("comp")) // "rec" is selected when "comp" is not
    | "comp" => selectedTags->Array.includes("comp")
    | "drill" | "dupr" => selectedTags->Array.includes(tag)
    | _ => false
    }
  }

  let isTagSelected = (tag: string, selectedTags: array<string>, category: tagCategory) => {
    switch category {
    | #"type" => isTagHighlighted(tag, selectedTags)
    | #level =>
      let levelTags = getLevelTags()
      let selectedLevelTags = selectedTags->Array.filter(t => levelTags->Array.includes(t))
      selectedTags->Array.includes(tag) ||
        (selectedLevelTags->Array.length == 0 && tag == "all level")
    }
  }

  let toggleTag = (tag: string, selectedTags: array<string>, category: tagCategory) => {
    switch category {
    | #"type" =>
      switch tag {
      | "rec" =>
        // Selecting "rec" means removing "comp" and keeping only valid rec sub-tags
        let validRecSubTags = getSubTags(#"rec")
        let allSubTags = getAllSubTags()
        selectedTags->Array.filter(t =>
          t !== "comp" && (validRecSubTags->Array.includes(t) || !(allSubTags->Array.includes(t)))
        )
      | "comp" =>
        // Toggle "comp" tag
        if selectedTags->Array.includes("comp") {
          // Deselecting "comp" means removing "comp" and keeping only valid rec sub-tags
          let validRecSubTags = getSubTags(#"rec")
          let allSubTags = getAllSubTags()
          selectedTags->Array.filter(t =>
            t !== "comp" && (validRecSubTags->Array.includes(t) || !(allSubTags->Array.includes(t)))
          )
        } else {
          // Selecting "comp" means adding "comp" and keeping compatible sub-tags
          let validCompSubTags = getSubTags(#comp)
          let allSubTags = getAllSubTags()
          let filteredTags =
            selectedTags->Array.filter(t =>
              validCompSubTags->Array.includes(t) || !(allSubTags->Array.includes(t))
            )
          filteredTags->Array.concat(["comp"])
        }
      | "drill" | "dupr" =>
        // Toggle sub tags
        if selectedTags->Array.includes(tag) {
          selectedTags->Array.filter(t => t !== tag)
        } else {
          selectedTags->Array.concat([tag])
        }
      | _ => selectedTags // Unknown tag, no change
      }
    | #level => {
        let levelTags = getLevelTags()
        let isSelected = isTagSelected(tag, selectedTags, category)
        if isSelected {
          selectedTags->Array.filter(t => t !== tag)
        } else if tag == "all level" {
          // If selecting "all level", remove all other level tags and add "all level"
          selectedTags->Array.filter(t => !(levelTags->Array.includes(t)))
        } else {
          // If selecting a specific level, remove "all level" and add the specific level
          selectedTags->Array.concat([tag])
        }
      }
    }
  }
}

// Component for rendering a group of related tags
module TagGroup = {
  @react.component
  let make = (
    ~tags: array<string>,
    ~selectedTags: array<string>,
    ~onTagsChange: array<string> => unit,
    ~category: tagCategory,
    ~label: string,
    ~description: option<string>=?,
    ~className: string="",
  ) => {
    let isMobile = useMobileDetection()
    let td = Lingui.UtilString.dynamic

    // Helper function to render a single tag button content
    let renderTagButtonContent = (tag: string, isSelected: bool, onToggle: unit => unit) => {
      <button
        type_="button"
        onClick={_ => onToggle()}
        className={Util.cx([
          "inline-flex items-center rounded-md px-3 py-2 text-sm font-semibold shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 cursor-help",
          isSelected
            ? "bg-indigo-600 text-white hover:bg-indigo-500 focus-visible:outline-indigo-600"
            : "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:outline-indigo-600",
        ])}>
        {td(tag)->React.string}
      </button>
    }

    // Helper function to render a tag with tooltip/popover
    let renderTagButton = (tag: string, isSelected: bool, onToggle: unit => unit) => {
      let buttonContent = renderTagButtonContent(tag, isSelected, onToggle)

      isMobile
        ? <Radix.Popover.Root key={tag}>
            <Radix.Popover.Trigger asChild=true> {buttonContent} </Radix.Popover.Trigger>
            <Radix.Popover.Content
              side=#top
              className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
              {EventTag.getTagTooltip(tag)->React.string}
            </Radix.Popover.Content>
          </Radix.Popover.Root>
        : <Radix.Tooltip.Root key={tag} delayDuration=200.>
            <Radix.Tooltip.Trigger asChild=true> {buttonContent} </Radix.Tooltip.Trigger>
            <Radix.Tooltip.Content
              side=#top
              className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
              {EventTag.getTagTooltip(tag)->React.string}
            </Radix.Tooltip.Content>
          </Radix.Tooltip.Root>
    }

    <div className={`col-span-full ${className}`}>
      <label className="block text-sm font-medium leading-6 text-gray-900">
        {label->React.string}
      </label>
      {isMobile
        ? {
            // Mobile version with popovers
            switch category {
            | #"type" => {
                let mainTags = TagLogic.getMainTypeTags()
                let currentState = TagLogic.getEventTypeState(selectedTags)

                <div className="mt-2 space-y-3">
                  <div className="flex gap-2">
                    {mainTags
                    ->Array.map(tag => {
                      let isSelected = TagLogic.isTagSelected(tag, selectedTags, category)
                      let onToggle = () => {
                        let newTags = TagLogic.toggleTag(tag, selectedTags, category)
                        onTagsChange(newTags)
                      }
                      renderTagButton(tag, isSelected, onToggle)
                    })
                    ->React.array}
                  </div>
                  {
                    let subTags = TagLogic.getSubTags(currentState)
                    if subTags->Array.length > 0 {
                      <div className="ml-4 flex gap-2">
                        {subTags
                        ->Array.map(subTag => {
                          let isSelected = TagLogic.isTagSelected(subTag, selectedTags, category)
                          let onToggle = () => {
                            let newTags = TagLogic.toggleTag(subTag, selectedTags, category)
                            onTagsChange(newTags)
                          }
                          renderTagButton(subTag, isSelected, onToggle)
                        })
                        ->React.array}
                      </div>
                    } else {
                      React.null
                    }
                  }
                </div>
              }
            | #level =>
              <div className="mt-2 flex gap-2">
                {tags
                ->Array.map(tag => {
                  let isSelected = TagLogic.isTagSelected(tag, selectedTags, category)
                  let onToggle = () => {
                    let newTags = TagLogic.toggleTag(tag, selectedTags, category)
                    onTagsChange(newTags)
                  }
                  renderTagButton(tag, isSelected, onToggle)
                })
                ->React.array}
              </div>
            }
          }
        : // Desktop version with tooltips wrapped in provider
          <Radix.Tooltip.Provider>
            {switch category {
            | #"type" => {
                let mainTags = TagLogic.getMainTypeTags()
                let currentState = TagLogic.getEventTypeState(selectedTags)

                <div className="mt-2 space-y-3">
                  <div className="flex gap-2">
                    {mainTags
                    ->Array.map(tag => {
                      let isSelected = TagLogic.isTagSelected(tag, selectedTags, category)
                      let onToggle = () => {
                        let newTags = TagLogic.toggleTag(tag, selectedTags, category)
                        onTagsChange(newTags)
                      }
                      renderTagButton(tag, isSelected, onToggle)
                    })
                    ->React.array}
                  </div>
                  {
                    let subTags = TagLogic.getSubTags(currentState)
                    if subTags->Array.length > 0 {
                      <div className="ml-4 flex gap-2">
                        {subTags
                        ->Array.map(subTag => {
                          let isSelected = TagLogic.isTagSelected(subTag, selectedTags, category)
                          let onToggle = () => {
                            let newTags = TagLogic.toggleTag(subTag, selectedTags, category)
                            onTagsChange(newTags)
                          }
                          renderTagButton(subTag, isSelected, onToggle)
                        })
                        ->React.array}
                      </div>
                    } else {
                      React.null
                    }
                  }
                </div>
              }
            | #level =>
              <div className="mt-2 flex gap-2">
                {tags
                ->Array.map(tag => {
                  let isSelected = TagLogic.isTagSelected(tag, selectedTags, category)
                  let onToggle = () => {
                    let newTags = TagLogic.toggleTag(tag, selectedTags, category)
                    onTagsChange(newTags)
                  }
                  renderTagButton(tag, isSelected, onToggle)
                })
                ->React.array}
              </div>
            }}
          </Radix.Tooltip.Provider>}
      {description
      ->Option.map(desc => <p className="mt-1 text-sm text-gray-500"> {desc->React.string} </p>)
      ->Option.getOr(React.null)}
    </div>
  }
}
