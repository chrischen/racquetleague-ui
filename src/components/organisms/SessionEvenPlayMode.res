%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

@rhf
type inputs = {numberOnBreak: Zod.number}

let schema = Zod.z->Zod.object(
  (
    {
      numberOnBreak: Zod.z->Zod.number({})->Zod.Int.int,
    }: inputs
  ),
)
@react.component
let make = (~breakCount: int, ~breakPlayersCount: int, ~onChangeBreakCount: int => unit) => {
  open Form
  let {register, handleSubmit, setValue} = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {numberOnBreak: breakCount->Int.toFloat},
    },
  )
  let onSubmit = (data: inputs) => {
    onChangeBreakCount(data.numberOnBreak->Float.toInt)
    setValue(NumberOnBreak, Value(""))
  }

  <div className="grid grid-cols-1 items-start gap-4">

    <form onSubmit={handleSubmit(onSubmit)}>
      <Input
        className="w-24 sm:w-32 md:w-48  flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
        label={t`How many players should rest? (currently ${breakPlayersCount->Int.toString} players are resting)`}
        type_="text"
        id="numberOnBreak"
        register={register(
          NumberOnBreak,
          ~options={
            setValueAs: v => {
              v == "" ? 0. : Float.fromString(v)->Option.getOr(0.)
            },
          },
        )}
      />
      <p className="mt-2 text-sm text-gray-500">
        {t`Set this to the number of players currently resting to enable even leveling of match counts. Set to 0 to disable and optimize match quality instead, but this may result in some players playing more matches than others.`}
        </p>
      <Form.Footer />
    </form>
  </div>
}
