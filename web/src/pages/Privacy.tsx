import LegalShell from "@/components/LegalShell";
import { SUPPORT_EMAIL } from "@/components/SiteLayout";

const Privacy = () => (
  <LegalShell
    title="Privacy Policy"
    effectiveDate="July 25, 2026"
    intro="This policy describes how the Taulbee Painting website and iPhone app handle information. There are no accounts, ads, or analytics trackers. Projects stay in your browser or on your iPhone. Photos and questions are processed only when you request an AI feature, and estimate details are sent only when you press Send."
  >
    <h2>Who we are</h2>
    <p>
      The Taulbee Painting app is operated by Taulbee Painting. For anything in
      this policy, contact us at{" "}
      <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
    </p>

    <h2>What the website and app store on your device</h2>
    <p>
      Everything you save is stored locally in this browser or on your iPhone and is not uploaded to us:
    </p>
    <ul>
      <li>Rooms, saved colors, sheens, and room photos in your Paint Vault</li>
      <li>Paint defect scans and their results</li>
      <li>Color visualizations and saved projects</li>
      <li>Maintenance reminders (delivered as local notifications)</li>
      <li>Paint Expert chat history</li>
      <li>Your activity timeline and app settings</li>
    </ul>
    <p>
      We cannot see this data. Deleting an item removes it. Clearing this website’s browser data or deleting the iPhone app removes all locally saved work for that device.
    </p>

    <h2>Photos and questions processed by AI</h2>
    <p>
      Some features use an AI processing service to generate results. This
      happens only when you actively use the feature, over an encrypted (HTTPS)
      connection:
    </p>
    <ul>
      <li>
        <strong>Color visualizer:</strong> the room or exterior photo you
        choose is sent to detect paintable surfaces and, when you request one,
        to create an HD photorealistic render.
      </li>
      <li>
        <strong>Paint defect scanner:</strong> the defect photo you choose is
        sent to produce a diagnosis.
      </li>
      <li>
        <strong>Paint Expert:</strong> the question text you type is sent to
        generate an answer.
      </li>
    </ul>
    <p>
      These photos and questions are processed transiently to return your
      result. They are used only to provide the feature — not for advertising,
      and not to build a profile of you. Processing may occur on servers
      located in the United States. Results are saved back to your device
      only.
    </p>

    <h2>Estimate requests</h2>
    <p>
      When you request an estimate, the website can send the details you entered — your name, contact details, room or project notes, and photos — directly to Taulbee Painting after you press Send. If direct delivery is unavailable, you can choose the email or share fallback. The iPhone app uses its available email or share flow. We use estimate information solely to respond and
      arrange your estimate. Emails you send us are kept as normal business
      correspondence; you can ask us to delete them at any time.
    </p>

    <h2>Device permissions</h2>
    <ul>
      <li>
        <strong>Camera</strong> — to photograph paint problems or rooms for
        analysis. Requested only when you use the camera.
      </li>
      <li>
        <strong>Photos</strong> — to pick existing images for scans and
        visualizations. Requested only when you open the picker.
      </li>
      <li>
        <strong>Notifications</strong> — to deliver the maintenance reminders
        you create. These are local notifications scheduled on your device.
      </li>
    </ul>
    <p>
      You can change any permission later in iOS Settings → Taulbee Painting.
    </p>

    <h2>What we don't do</h2>
    <ul>
      <li>No user accounts and no sign-in</li>
      <li>No cross-device syncing; browser and iPhone records remain separate</li>
      <li>No analytics, tracking SDKs, or advertising</li>
      <li>We do not sell or share your personal information</li>
      <li>No background collection — data leaves your device only through the actions described above</li>
    </ul>

    <h2>Your choices and rights</h2>
    <ul>
      <li>
        <strong>Access or deletion of local data:</strong> manage it directly in the website or app. The website’s More page includes a confirmed Delete All option.
      </li>
      <li>
        <strong>Emails you've sent us:</strong> write to{" "}
        <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a> to request a
        copy or deletion of your correspondence.
      </li>
      <li>
        <strong>Permissions:</strong> revoke camera, photos, or notification
        access in iOS Settings at any time.
      </li>
    </ul>

    <h2>Children</h2>
    <p>
      The app is not directed to children under 13, and we do not knowingly
      collect personal information from them.
    </p>

    <h2>Changes to this policy</h2>
    <p>
      If we change this policy, we will update this page and its effective
      date. Material changes will be highlighted in the app or on this site.
    </p>

    <h2>Contact</h2>
    <p>
      Questions about privacy? Email{" "}
      <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
    </p>
  </LegalShell>
);

export default Privacy;
