%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

@rhf
type inputsUser = {name: Zod.string_}

let schema = Zod.z->Zod.object(
  (
    {
      name: Zod.z->Zod.string({})->Zod.String.min(1),
    }: inputsUser
  ),
)
@react.component
let make = (~eventId: string, ~onPlayerAdd: inputsUser => unit) => {
  open Form
  let {register, handleSubmit, setValue} = useFormOfInputsUser(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {},
    },
  )
  let onSubmit = (data: inputsUser) => {
    onPlayerAdd(data)
    setValue(Name, Value(""))
  }

  <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-2 md:gap-8 mb-2">

    <QRCode value={"https://www.pkuru.com/events/" ++ eventId} />
    <form onSubmit={handleSubmit(onSubmit)}>
      <Input
        className="w-24 sm:w-32 md:w-48  flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
        label={t`Player Name`}
        type_="text"
        id="name"
        register={register(
          Name,
          // ~options={
          //   setValueAs: v => {
          //     v == "" ? 0. : Float.fromString(v)->Option.getOr(1.)
          //   },
          // },
        )}
      />
      <Form.Footer />
    </form>
  </div>
}
