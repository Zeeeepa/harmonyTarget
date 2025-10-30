@Builder
export function SectionHeader(title: string) {
  Text(title)
    .fontSize(20)
    .fontWeight(FontWeight.Bold)
    .width('100%')
    .textAlign(TextAlign.Start);
}
