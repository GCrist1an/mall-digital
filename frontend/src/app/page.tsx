import Image from "next/image";

const steps = [
  {
    title: "Descubre tiendas",
    description: "Explora tiendas locales verificadas de tu ciudad.",
  },
  {
    title: "Arma tu carrito",
    description: "Agrega productos de una o varias tiendas.",
  },
  {
    title: "Pide por WhatsApp",
    description: "Envía tu pedido a cada tienda por WhatsApp.",
  },
] as const;

export default function Home() {
  return (
    <>
      <header className="bg-brand-green">
        <div className="mx-auto flex max-w-3xl items-center gap-3 px-4 py-3">
          <Image
            src="/logo.png"
            alt=""
            width={40}
            height={40}
            className="rounded-lg"
            priority
          />
          <span className="text-xl font-bold tracking-tight text-brand-cream">
            De Aquí
          </span>
        </div>
      </header>

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-10 sm:py-16">
        <section className="flex flex-col items-center text-center">
          <Image
            src="/logo.png"
            alt="Logo de De Aquí"
            width={112}
            height={112}
            className="rounded-3xl shadow-md sm:size-36"
          />
          <h1 className="mt-6 text-3xl leading-tight font-bold text-balance sm:text-4xl">
            Tiendas locales verificadas de Pereira y Dosquebradas
          </h1>
        </section>

        <section aria-labelledby="como-funciona" className="mt-12 sm:mt-16">
          <h2
            id="como-funciona"
            className="text-center text-2xl font-bold sm:text-3xl"
          >
            Cómo funciona
          </h2>
          <ol className="mt-6 grid gap-4 sm:grid-cols-3">
            {steps.map((step, index) => (
              <li
                key={step.title}
                className="flex items-start gap-4 rounded-2xl bg-white/70 p-4 shadow-sm ring-1 ring-brand-green/10 sm:flex-col sm:items-center sm:text-center"
              >
                <span
                  aria-hidden="true"
                  className="flex size-10 shrink-0 items-center justify-center rounded-full bg-brand-yellow text-lg font-bold text-brand-green"
                >
                  {index + 1}
                </span>
                <div>
                  <h3 className="text-lg font-semibold">{step.title}</h3>
                  <p className="mt-1 text-brand-green/80">{step.description}</p>
                </div>
              </li>
            ))}
          </ol>
        </section>
      </main>

      <footer className="bg-brand-green text-brand-cream">
        <p className="mx-auto max-w-3xl px-4 py-4 text-center text-sm">
          De Aquí · Pereira y Dosquebradas
        </p>
      </footer>
    </>
  );
}
