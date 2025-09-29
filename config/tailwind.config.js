module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography')
  ],
  theme: {
    extend: {
      colors: {
        primary: {"50":"#eff6ff","100":"#dbeafe","200":"#bfdbfe","300":"#93c5fd","400":"#60a5fa","500":"#3b82f6","600":"#2563eb","700":"#1d4ed8","800":"#1e40af","900":"#1e3a8a"}
      },
      fontSize: {
        '2xs': ['0.625rem', { lineHeight: '0.75rem' }]
      },
      lineClamp: {
        8: '8'
      },
      width: {
        '3%': '3%'
      }
    },
    fontFamily: {
      'body': [
        'Montserrat',
        'sans-serif'
      ],
      'sans': [
        'Montserrat',
        'sans-serif'
      ],
    }
  },
  variants: {
    rotate: ['responsive', 'hover', 'focus']
  }
}