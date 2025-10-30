interface InfoCardProps {
  title?: string;
  body: string;
  tone?: 'default' | 'warning' | 'success';
}

interface ColorScheme {
  bg: string;
  text: string;
}

class ColorPalette {
  defaultScheme: ColorScheme = { bg: '#f0f0f0', text: '#202020' };
  warningScheme: ColorScheme = { bg: '#fff6e6', text: '#8a4f00' };
  successScheme: ColorScheme = { bg: '#ecf8f2', text: '#14532d' };

  getColors(tone: string): ColorScheme {
    if (tone === 'warning') {
      return this.warningScheme;
    } else if (tone === 'success') {
      return this.successScheme;
    }
    return this.defaultScheme;
  }
}

const palette = new ColorPalette();

function getColorScheme(tone?: string): ColorScheme {
  return palette.getColors(tone ?? 'default');
}

@Builder
export function InfoCard(props: InfoCardProps) {
  Column({ space: 8 }) {
    if (props.title) {
      Text(props.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(getColorScheme(props.tone).text)
        .width('100%')
        .textAlign(TextAlign.Start);
    }
    Text(props.body)
      .fontSize(14)
      .fontColor(getColorScheme(props.tone).text)
      .width('100%')
      .textAlign(TextAlign.Start);
  }
  .padding(15)
  .backgroundColor(getColorScheme(props.tone).bg)
  .borderRadius(10)
}
