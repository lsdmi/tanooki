const defaultTheme = require('tailwindcss/defaultTheme')

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
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {"50":"#eff6ff","100":"#dbeafe","200":"#bfdbfe","300":"#93c5fd","400":"#60a5fa","500":"#3b82f6","600":"#2563eb","700":"#1d4ed8","800":"#1e40af","900":"#1e3a8a"}
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
      oswald: ['Oswald', ...defaultTheme.fontFamily.sans]
    },
    rotate: {
      "2": "2deg"
    }
  },
  variants: {
    rotate: ['responsive', 'hover', 'focus']
  }
}